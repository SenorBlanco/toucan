// Copyright 2023 The Toucan Authors
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

#include "gen_bindings.h"

#include <stdlib.h>
#include <string.h>
#include <cassert>

#include <ast/symbol.h>

namespace Toucan {

GenBindings::GenBindings(SymbolTable* symbols,
                         TypeTable*   types,
                         FILE*        file,
                         FILE*        header,
                         bool         dumpStmtsAsSource)
    : symbols_(symbols),
      types_(types),
      file_(file),
      header_(header),
      dumpStmtsAsSource_(dumpStmtsAsSource),
      sourcePass_(file_, &typeMap_) {}

void GenBindings::GenType(Type* type) {
  if (type->IsInteger()) {
    IntegerType* i = static_cast<IntegerType*>(type);
    fprintf(file_, "types->GetInteger(%d, %s)", i->GetBits(), i->Signed() ? "true" : "false");
  } else if (type->IsFloatingPoint()) {
    FloatingPointType* f = static_cast<FloatingPointType*>(type);
    fprintf(file_, "types->GetFloatingPoint(%d)", f->GetBits());
  } else if (type->IsBool()) {
    fprintf(file_, "types->GetBool()");
  } else if (type->IsVector()) {
    VectorType* v = static_cast<VectorType*>(type);
    fprintf(file_, "types->GetVector(");
    GenType(v->GetComponentType());
    fprintf(file_, ", %d)", v->GetLength());
  } else if (type->IsMatrix()) {
    MatrixType* m = static_cast<MatrixType*>(type);
    fprintf(file_, "types->GetMatrix(");
    GenType(m->GetColumnType());
    fprintf(file_, ", %d)", m->GetNumColumns());
  } else if (type->IsString()) {
    fprintf(file_, "types->GetString()");
  } else if (type->IsVoid()) {
    fprintf(file_, "types->GetVoid()");
  } else if (type->IsNull()) {
    fprintf(file_, "types->GetNull()");
  } else if (type->IsAuto()) {
    fprintf(file_, "types->GetAuto()");
  } else if (type->IsClassTemplate()) {
    ClassTemplate* classTemplate = static_cast<ClassTemplate*>(type);
    fprintf(file_, "  types->Make<ClassTemplate>(\"%s\", TypeList({",
            classTemplate->GetName().c_str());
    for (Type* const& type : classTemplate->GetFormalTemplateArgs()) {
      assert(type->IsFormalTemplateArg());
      fprintf(file_, "types->GetFormalTemplateArg(\"%s\")",
              static_cast<FormalTemplateArg*>(type)->GetName().c_str());
      if (&type != &classTemplate->GetFormalTemplateArgs().back()) { fprintf(file_, ", "); }
    }
    if (header_) { fprintf(header_, "struct %s;\n", classTemplate->GetName().c_str()); }
    fprintf(file_, "}))");
  } else if (type->IsClass()) {
    ClassType* classType = static_cast<ClassType*>(type);
    if (classType->GetTemplate()) {
      fprintf(file_,
              "  types->GetClassTemplateInstance(static_cast<ClassTemplate*>(typeList[%d]), {",
              typeMap_[classType->GetTemplate()]);
      for (Type* const& type : classType->GetTemplateArgs()) {
        fprintf(file_, "typeList[%d]", typeMap_[type]);
        if (&type != &classType->GetTemplateArgs().back()) { fprintf(file_, ", "); }
      }
      fprintf(file_, "} )");
    } else {
      fprintf(file_, "  types->Make<ClassType>(\"%s\")", classType->GetName().c_str());
      if (header_) { fprintf(header_, "struct %s;\n", classType->GetName().c_str()); }
    }
#if 0
    if (nativeClasses && classType->IsNative()) {
      fprintf(nativeClasses, "  ClassType* %s;";
    }
#endif
  } else if (type->IsEnum()) {
    EnumType* enumType = static_cast<EnumType*>(type);
    fprintf(file_, "  types->Make<EnumType>(\"%s\")", enumType->GetName().c_str());
    if (header_) {
      fprintf(header_, "enum %s {\n", enumType->GetName().c_str());
      const EnumValueVector& values = enumType->GetValues();
      for (EnumValue const& v : values) {
        fprintf(header_, "  %s = %d,\n", v.id.c_str(), v.value);
      }
      fprintf(header_, "};\n");
    }
  } else if (type->IsPtr()) {
    PtrType* ptrType = static_cast<PtrType*>(type);
    fprintf(file_, "types->Get%sPtrType(", type->IsStrongPtr() ? "Strong" : "Weak");
    if (ptrType->GetBaseType()) {
      fprintf(file_, "typeList[%d]", typeMap_[ptrType->GetBaseType()]);
    } else {
      fprintf(file_, "nullptr");
    }
    fprintf(file_, ")");
  } else if (type->IsArray()) {
    ArrayType* arrayType = static_cast<ArrayType*>(type);
    fprintf(file_, "types->GetArrayType((typeList[%d]), %d, MemoryLayout::Default)",
            typeMap_[arrayType->GetElementType()], arrayType->GetNumElements());
  } else if (type->IsFormalTemplateArg()) {
    FormalTemplateArg* formalTemplateArg = static_cast<FormalTemplateArg*>(type);
    fprintf(file_, "types->GetFormalTemplateArg(\"%s\")", formalTemplateArg->GetName().c_str());
  } else if (type->IsQualified()) {
    QualifiedType* qualifiedType = static_cast<QualifiedType*>(type);
    fprintf(file_, "types->GetQualifiedType(typeList[%d], %d)",
            typeMap_[qualifiedType->GetBaseType()], qualifiedType->GetQualifiers());
  } else if (type->IsUnresolvedScopedType()) {
    auto unresolvedScopedType = static_cast<UnresolvedScopedType*>(type);
    fprintf(
        file_,
        "types->GetUnresolvedScopedType(static_cast<FormalTemplateArg*>(typeList[%d]), \"%s\")",
        typeMap_[unresolvedScopedType->GetBaseType()], unresolvedScopedType->GetID().c_str());
  } else {
    assert(!"unknown type");
    exit(-1);
  }
}

void GenBindings::Run() {
  const TypeVector& types = types_->GetTypes();
  typeMap_.clear();
  // First assign ID's to all resolved types.
  int numTypes = types.size();
  fprintf(file_, "#include <cstdint>\n");
  fprintf(file_, "#include <ast/ast.h>\n");
  fprintf(file_, "#include <ast/native_class.h>\n");
  fprintf(file_, "#include <ast/symbol.h>\n");
  fprintf(file_, "#include <ast/type.h>\n");
  fprintf(file_, "namespace Toucan {\n\n");
  fprintf(file_, "void InitTypes(SymbolTable* symbols, TypeTable* types, NodeVector* nodes) {\n");
  fprintf(file_, "  ClassType* c;\n");
  fprintf(file_, "  EnumType* e;\n");
  fprintf(file_, "  Type** typeList = new Type*[%d];\n", numTypes);
  fprintf(file_, "  ASTNode** nodeList = new ASTNode*[%d];\n", 1000 /* FIXME num_nodes */);
  fprintf(file_, "  Expr** exprs = reinterpret_cast<Expr**>(nodeList);\n");
  fprintf(file_, "  Stmt** stmts = reinterpret_cast<Stmt**>(nodeList);\n");
  fprintf(file_, "  Stmts** stmtss = reinterpret_cast<Stmts**>(nodeList);\n");
  fprintf(file_, "  ArgList** argLists = reinterpret_cast<ArgList**>(nodeList);\n");
  fprintf(file_, "  Scope* scope;\n");
  fprintf(file_, "  std::shared_ptr<Var> v;\n");
  fprintf(file_, "  Type* returnType;\n");
  fprintf(file_, "  Method *m;\n");
  fprintf(file_, "  nodeList[0] = nullptr;\n");
  fprintf(file_, "\n");
  if (header_) {
    fprintf(header_, "#include <cstdint>\n");
    fprintf(header_, "extern \"C\" {\n");
    fprintf(header_, "namespace Toucan {\n\n");
    fprintf(header_, "class ClassType;\n");
    fprintf(header_, "class Type;\n\n");
    fprintf(header_, "struct ControlBlock {\n");
    fprintf(header_, "  uint32_t    strongRefs = 0;\n");
    fprintf(header_, "  uint32_t    weakRefs = 0;\n");
    fprintf(header_, "  uint32_t    arrayLength;\n");
    fprintf(header_, "  Type*       type = nullptr;\n");
    fprintf(header_, "  void*       vtable = nullptr;\n");
    fprintf(header_, "};\n\n");
    fprintf(header_, "struct Object {\n");
    fprintf(header_, "  void*          ptr;\n");
    fprintf(header_, "  ControlBlock  *controlBlock;\n");
    fprintf(header_, "};\n\n");
  }
  int id = 0;
  for (auto type : types) {
    typeMap_[type] = id;
    fprintf(file_, "  typeList[%d] = ", id++);
    GenType(type);
    fprintf(file_, ";\n");
  }
  // Now that we have defined the types, resolve the references.
  for (auto type : types) {
    if (type->IsClass()) {
      GenBindingsForClass(static_cast<ClassType*>(type));
    } else if (type->IsEnum()) {
      GenBindingsForEnum(static_cast<EnumType*>(type));
    }
  }
  fprintf(file_, "  delete[] typeList;\n");
  fprintf(file_, "  delete[] nodeList;\n");
  fprintf(file_, "}\n\n");
  fprintf(file_, "};\n");
  if (header_) { fprintf(header_, "\n};\n}\n"); }
}

void PrintNativeType(FILE* file, Type* type) {
  if (type->IsVoid()) {
    fprintf(file, "void");
  } else if (type->IsInteger()) {
    IntegerType* integerType = static_cast<IntegerType*>(type);
    fprintf(file, "%sint%d_t", integerType->Signed() ? "" : "u", integerType->GetBits());
  } else if (type->IsBool()) {
    fprintf(file, "bool");
  } else if (type->IsFloat()) {
    fprintf(file, "float");
  } else if (type->IsDouble()) {
    fprintf(file, "double");
  } else if (type->IsClass()) {
    ClassType* c = static_cast<ClassType*>(type);
    if (c->IsNative()) {
      fprintf(file, "%s", c->GetName().c_str());
    } else {
      fprintf(file, "Object");
    }
  } else if (type->IsEnum()) {
    EnumType* e = static_cast<EnumType*>(type);
    fprintf(file, "%s", e->GetName().c_str());
  } else if (type->IsPtr()) {
    Type* baseType = static_cast<PtrType*>(type)->GetBaseType();
    if (baseType->IsQualified()) {
      baseType = static_cast<QualifiedType*>(baseType)->GetBaseType();
    }
    if (baseType->IsVoid() || baseType->IsFormalTemplateArg() || baseType->IsArray()) {
      fprintf(file, "Object*");
    } else {
      PrintNativeType(file, baseType);
      fprintf(file, "*");
    }
  } else if (type->IsArray()) {
    ArrayType* arrayType = static_cast<ArrayType*>(type);
    Type*      elementType = arrayType->GetElementType();
    if (elementType->IsVector()) {
      PrintNativeType(file, static_cast<VectorType*>(type)->GetComponentType());
    } else if (elementType->IsMatrix()) {
      PrintNativeType(file, static_cast<MatrixType*>(type)->GetColumnType()->GetComponentType());
    } else {
      PrintNativeType(file, elementType);
    }
    fprintf(file, "*");
  } else if (type->IsVector()) {
    PrintNativeType(file, static_cast<VectorType*>(type)->GetComponentType());
    fprintf(file, "*");
  } else if (type->IsMatrix()) {
    PrintNativeType(file, static_cast<MatrixType*>(type)->GetColumnType()->GetComponentType());
    fprintf(file, "*");
  } else if (type->IsFormalTemplateArg()) {
    fprintf(file, "void");
  } else if (type->IsQualified()) {
    PrintNativeType(file, static_cast<QualifiedType*>(type)->GetBaseType());
  } else {
    fprintf(stderr, "PrintNativeType():  unknown type \"%s\"\n", type->ToString().c_str());
    exit(-2);
  }
}

void GenBindings::GenBindingsForMethod(ClassType* classType, Method* method) {
  fprintf(file_, "  returnType = typeList[%d];\n", typeMap_[method->returnType]);
  fprintf(file_, "  m = new Method(0");
  if (method->modifiers & Method::STATIC) { fprintf(file_, " | Method::STATIC"); }
  if (method->modifiers & Method::VIRTUAL) { fprintf(file_, " | Method::VIRTUAL"); }
  std::string name = method->name;
  if (name[0] == '~') { name = "Destroy"; }
  fprintf(file_, ", returnType, \"%s\", static_cast<ClassType*>(typeList[%d]));\n", name.c_str(),
          typeMap_[method->classType]);
  const VarVector& argList = method->formalArgList;
  for (int i = 0; i < argList.size(); ++i) {
    Var*  var = argList[i].get();
    Expr* defaultValue = method->defaultArgs[i];
    int   defaultValueId = defaultValue ? sourcePass_.Resolve(defaultValue) : 0;
    fprintf(file_, "  m->AddFormalArg(\"%s\", typeList[%d], ", var->name.c_str(),
            typeMap_[var->type]);
    if (defaultValue) {
      fprintf(file_, "exprs[%d]", defaultValueId);
    } else {
      fprintf(file_, "nullptr");
    }
    fprintf(file_, ");\n");
  }
  fprintf(file_, "  c->AddMethod(m, %d);\n", method->index);
  if (classType->IsNative()) {
    if (header_) {
#if defined(_WIN32) && !TARGET_IS_WASM
      fprintf(header_, "__declspec(dllexport) ");
#endif
      PrintNativeType(header_, method->returnType);
      fprintf(header_, " %s_%s(", classType->GetName().c_str(), name.c_str());
      if (classType->IsClassTemplate() && method->modifiers & Method::STATIC) {
        fprintf(header_, "int qualifiers, ");
        ClassTemplate* classTemplate = static_cast<ClassTemplate*>(classType);
        for (Type* arg : classTemplate->GetFormalTemplateArgs()) {
          FormalTemplateArg* formalTemplateArg = static_cast<FormalTemplateArg*>(arg);
          fprintf(header_, "Type* %s", formalTemplateArg->GetName().c_str());
          if (arg != classTemplate->GetFormalTemplateArgs().back() || !argList.empty()) {
            fprintf(header_, ", ");
          }
        }
      }
      for (const std::shared_ptr<Var>& var : argList) {
        PrintNativeType(header_, var->type);
        if (var->name == "this") {
          fprintf(header_, " This");
        } else {
          fprintf(header_, " %s", var->name.c_str());
        }
        if (&var != &argList.back()) { fprintf(header_, ", "); }
      }
      fprintf(header_, ");\n");
    }
  }
  if (method->shaderType == ShaderType::Vertex) {
    fprintf(file_, "  m->shaderType = ShaderType::Vertex;\n");
  } else if (method->shaderType == ShaderType::Fragment) {
    fprintf(file_, "  m->shaderType = ShaderType::Fragment;\n");
  } else if (method->shaderType == ShaderType::Compute) {
    fprintf(file_, "  m->shaderType = ShaderType::Compute;\n");
  } else if (dumpStmtsAsSource_ && method->stmts) {
    int id = sourcePass_.Resolve(method->stmts);
    fprintf(file_, "  m->stmts = stmtss[%d];\n", id);
  }
  if (!method->spirv.empty()) {
    fprintf(file_, "  m->spirv = {\n");
    for (uint32_t op : method->spirv) {
      fprintf(file_, "%d, ", op);
    }
    fprintf(file_, "};\n");
  }
  if (!method->wgsl.empty()) { fprintf(file_, "  m->wgsl = R\"(%s)\";\n", method->wgsl.c_str()); }
}

void GenBindings::GenBindingsForClass(ClassType* classType) {
  if (classType->GetTemplate() && classType->IsNative()) { return; }
  fprintf(file_, "  c = static_cast<ClassType*>(typeList[%d]);\n", typeMap_[classType]);
  if (classType->IsNative()) {
    fprintf(file_, "  c->SetNative(true);\n");
    if (classType->IsNative()) {
      fprintf(file_, "  NativeClass::%s = c;\n;", classType->GetName().c_str());
    }
  }
  fprintf(file_, "  scope = symbols->PushNewScope();\n");
  fprintf(file_, "  scope->classType = c;\n");
  fprintf(file_, "  c->SetScope(scope);\n");
  if (ClassType* parent = classType->GetParent()) {
    fprintf(file_, "  c->SetParent(static_cast<ClassType*>(typeList[%d]));\n", typeMap_[parent]);
  }
  for (const auto& i : classType->GetFields()) {
    Field* field = i.get();
    fprintf(file_, "  c->AddField(\"%s\", typeList[%d]);\n", field->name.c_str(),
            typeMap_[field->type]);
  }
  for (const auto& m : classType->GetMethods()) {
    Method* method = m.get();
    GenBindingsForMethod(classType, method);
  }
  if (classType->GetScope()) {
    for (const auto& pair : classType->GetScope()->types) {
      fprintf(file_, "  scope->types[\"%s\"] = typeList[%d];\n", pair.first.c_str(),
              typeMap_[pair.second]);
    }
  }
  fprintf(file_, "  symbols->PopScope();\n");
  if (!classType->GetTemplate()) {
    fprintf(file_, "  symbols->DefineType(\"%s\", c);\n\n", classType->GetName().c_str());
  }
}

void GenBindings::GenBindingsForEnum(EnumType* enumType) {
  fprintf(file_, "  e = static_cast<EnumType*>(typeList[%d]);\n", typeMap_[enumType]);
  for (const EnumValue& v : enumType->GetValues()) {
    fprintf(file_, "  e->Append(\"%s\", %d);\n", v.id.c_str(), v.value);
  }
  fprintf(file_, "  symbols->DefineType(\"%s\", e);\n\n", enumType->GetName().c_str());
}

};  // namespace Toucan
