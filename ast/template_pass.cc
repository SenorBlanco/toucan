// Copyright 2026 The Toucan Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "template_pass.h"

#include <assert.h>
#include <stdarg.h>
#include <string.h>

namespace Toucan {

struct TemplateArg {
  std::string id;
  ASTType*    value;
}

TemplatePass::TemplatePass(NodeVector*              nodes,
                           TypeTable*               types,
                           std::vector<TemplateArg> templateArgs,
                           NewClassCallback         newClassCallback)
    : CopyVisitor(nodes),
      types_(types),
      templateArgs_(templateArgs),
      newClassCallback_(newClassCallback) {}

Method* TypeReplacementPass::ResolveMethod(Method* m) {
  Method* result = new Method(m->modifiers, ResolveType(m->returnType), m->name.c_str(),
                              static_cast<ClassType*>(ResolveType(m->classType)));
  result->templateMethod = m;
  for (int i = 0; i < m->formalArgList.size(); ++i) {
    Var* var = m->formalArgList[i].get();
    result->AddFormalArg(var->name, ResolveType(var->type), m->defaultArgs[i]);
  }
  if (m->stmts) {
    result->stmts = Resolve(m->stmts);
  }
  if (m->initializer) result->initializer = Resolve(m->initializer);
  return result;
}

void TypeReplacementPass::ResolveClassInstance(ClassTemplate* classTemplate, ClassType* instance) {
  srcTypes_.push_back(classTemplate);
  dstTypes_.push_back(instance);
  if (auto parent = classTemplate->GetParent()) {
    instance->SetParent(static_cast<ClassType*>(ResolveType(parent)));
  }
  for (const auto& i : classTemplate->GetTypes()) {
    instance->DefineType(i.first, ResolveType(i.second));
  }
  for (const auto& i : classTemplate->GetMethods()) {
    Method* method = i.get();
    instance->AddMethod(ResolveMethod(method));
  }
  for (const auto& i : classTemplate->GetFields()) {
    Field* field = i.get();
    instance->AddField(field->name, ResolveType(field->type), Resolve(field->defaultValue));
  }
}

Type* TypeReplacementPass::PushQualifiers(Type* type, int qualifiers) {
  if (type->IsStrongPtr()) {
    return types_->GetStrongPtrType(
        PushQualifiers(static_cast<PtrType*>(type)->GetBaseType(), qualifiers));
  } else if (type->IsWeakPtr()) {
    return types_->GetWeakPtrType(
        PushQualifiers(static_cast<PtrType*>(type)->GetBaseType(), qualifiers));
  } else if (type->IsArray()) {
    auto arrayType = static_cast<ArrayType*>(type);
    return types_->GetArrayType(
        PushQualifiers(arrayType->GetElementType(), qualifiers),
        arrayType->GetNumElements(), arrayType->GetMemoryLayout());
  } else {
    return types_->GetQualifiedType(type, qualifiers);
  }
}

Result TypeReplacementPass::Visit(ASTTemplateFormalArg* arg) {
  for (auto templateArg : templateArgs_) {
    if (arg->GetName() == templateArg.name) { return templateArg.value; }
  }
  return arg;
}

Result TemplatePass::Visit(ASTQualifiedType* node) {
  int   qualifiers;
  Type* result = Resolve(node->GetBaseType());
  return PushQualifiers(result, node->GetQualifiers());
}
  } else if (type->IsClass() && static_cast<ClassType*>(type)->GetTemplate()) {
    ClassType* instance = static_cast<ClassType*>(type);
    TypeList   newArgs;
    for (Type* const& arg : instance->GetTemplateArgs()) {
      newArgs.push_back(ResolveType(arg));
    }
    return types_->GetClassTemplateInstance(instance->GetTemplate(), newArgs, newClassCallback_);
  } else if (type->IsUnresolvedScopedType()) {
    auto  ust = static_cast<UnresolvedScopedType*>(type);
    Type* newType = ResolveType(ust->GetBaseType());
    if (newType->IsClass()) {
      auto classType = static_cast<ClassType*>(newType);
      if (ust->GetID() == "BaseClass") {
        if (auto parent = classType->GetParent()) { newType = parent; }
      } else {
        newType = static_cast<ClassType*>(newType)->FindType(ust->GetID());
        if (!newType) {
          Error("Type \"%s\" not found", ust->GetID().c_str());
        }
      }
    } else {
      Error("\"%s\" is not a class", newType->ToString().c_str());
    }
    return newType;
  }
  return type;
}

TypeList* TypeReplacementPass::ResolveTypes(TypeList* typeList) {
  if (!typeList) { return nullptr; }
  TypeList* list = new TypeList();  // FIXME: who owns this?
  for (Type* const& type : *typeList) {
    list->push_back(ResolveType(type));
  }
  return list;
}

Result TypeReplacementPass::Visit(Stmts* stmts) {
  Stmts* newStmts = Make<Stmts>();
  newStmts->SetFileLocation(stmts->GetFileLocation());

  for (Stmt* const& it : stmts->GetStmts()) {
    Stmt* stmt = Resolve(it);
    if (stmt) newStmts->Append(stmt);
  }
  return newStmts;
}

Result TypeReplacementPass::Default(ASTNode* node) {
  assert(false);
  return nullptr;
}

Result TypeReplacementPass::Error(const char* fmt, ...) {
  va_list argp;
  va_start(argp, fmt);
  vfprintf(stderr, fmt, argp);
  fprintf(stderr, "\n");
  numErrors_++;
  return nullptr;
}

};  // namespace Toucan
