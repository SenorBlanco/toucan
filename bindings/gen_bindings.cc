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
#include <iostream>
#include <sstream>

#include <ast/symbol.h>

namespace Toucan {

namespace {

const char* MemoryLayoutToString(MemoryLayout layout) {
  switch (layout) {
    case MemoryLayout::Default: return "Default";
    case MemoryLayout::Storage: return "Storage";
    case MemoryLayout::Uniform: return "Uniform";
    default: assert(!"unknown MemoryLayout"); return "";
  }
}

std::string ConvertType(Type* type, const std::string& str) {
  if (type->IsPtr()) {
    return ConvertType(static_cast<PtrType*>(type)->GetBaseType(), "*" + str);
  } else if (type->IsArray()) {
    ArrayType* atype = static_cast<ArrayType*>(type);
    return ConvertType(atype->GetElementType(), str + "[" + std::to_string(atype->GetNumElements()) + "]");
  } else if (type->IsClass()) {
    return static_cast<ClassType*>(type)->GetName() + " " + str;
  } else if (type->IsByte()) {
    return "int8_t " + str;
  } else if (type->IsUByte()) {
    return "uint8_t " + str;
  } else if (type->IsShort()) {
    return "int16_t " + str;
  } else if (type->IsUShort()) {
    return "uint16_t " + str;
  } else if (type->IsInt()) {
    return "int32_t " + str;
  } else if (type->IsUInt()) {
    return "uint32_t " + str;
  } else if (type->IsEnum()) {
    return static_cast<EnumType*>(type)->GetName() + " " + str;
  } else if (type->IsFloat()) {
    return "float " + str;
  } else if (type->IsDouble()) {
    return "double " + str;
  } else if (type->IsBool()) {
    return "bool " + str;
  } else if (type->IsVector()) {
    VectorType* v = static_cast<VectorType*>(type);
    return ConvertType(v->GetComponentType(), str + "[" + std::to_string(v->GetLength()) + "]");
  } else if (type->IsMatrix()) {
    MatrixType* m = static_cast<MatrixType*>(type);
    return ConvertType(m->GetColumnType(), str + "[" + std::to_string(m->GetNumColumns()) + "]");
  } else if (type->IsVoid()) {
    return "void " + str;
  } else if (type->IsQualified()) {
    return ConvertType(static_cast<QualifiedType*>(type)->GetBaseType(), str);
  } else {
    assert(!"ConvertType:  unknown type");
    return 0;
  }
}

}  // namespace

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

int GenBindings::GenType(Type* type) {
  auto iter = typeMap_.find(type);
  if (iter != typeMap_.end()) {
    return iter->second;
  }
  int id = numTypes_++;
  typeMap_[type] = id;
  std::stringstream result;
  result << "  Type* type" << std::to_string(id) << " = ";
  if (type->IsInteger()) {
    IntegerType* i = static_cast<IntegerType*>(type);
    result << "types->GetInteger(" << std::to_string(i->GetBits()) << ", "
           << (i->Signed() ? "true" : "false") << ")";
  } else if (type->IsFloatingPoint()) {
    FloatingPointType* f = static_cast<FloatingPointType*>(type);
    result << "types->GetFloatingPoint(" << std::to_string(f->GetBits()) << ")";
  } else if (type->IsBool()) {
    result << "types->GetBool()";
  } else if (type->IsVector()) {
    VectorType* v = static_cast<VectorType*>(type);
    result << "types->GetVector(type" << std::to_string(GenType(v->GetComponentType())) << ", " << std::to_string(v->GetLength()) << ")";
  } else if (type->IsMatrix()) {
    MatrixType* m = static_cast<MatrixType*>(type);
    result << "types->GetMatrix(static_cast<VectorType*>(type" << GenType(m->GetColumnType()) << "), " << std::to_string(m->GetNumColumns()) << ")";
  } else if (type->IsString()) {
    result << "types->GetString()";
  } else if (type->IsVoid()) {
    result << "types->GetVoid()";
  } else if (type->IsAuto()) {
    result << "types->GetAuto()";
  } else if (type->IsClassTemplate()) {
    ClassTemplate* classTemplate = static_cast<ClassTemplate*>(type);
    result << "types->Make<ClassTemplate>(\"" << classTemplate->GetName().c_str() << "\", TypeList({";
    for (Type* const& type : classTemplate->GetFormalTemplateArgs()) {
      assert(type->IsFormalTemplateArg());
      result << "types->GetFormalTemplateArg(\""
             << static_cast<FormalTemplateArg*>(type)->GetName() << "\")";
      if (&type != &classTemplate->GetFormalTemplateArgs().back()) result << ", ";
    }
    result << "}))";
    if (header_) {
      std::stringstream hresult;
      hresult << "struct " << classTemplate->GetName() << ";\n";
      fwrite(hresult.str().c_str(), hresult.str().length(), 1, header_);
    }
  } else if (type->IsClass()) {
    ClassType* classType = static_cast<ClassType*>(type);
    if (classType->GetTemplate()) {
      // FIXME: remove this space
      result << "  types->GetClassTemplateInstance(static_cast<ClassTemplate*>(type" << GenType(classType->GetTemplate()) << "), {";
      for (Type* const& type : classType->GetTemplateArgs()) {
        result << "type" << GenType(type);
        if (&type != &classType->GetTemplateArgs().back()) { result << ", "; }
      }
      result << "} )";
    } else {
      result << "types->Make<ClassType>(\"" << classType->GetName() << "\")";
      if (header_) {
        std::stringstream hresult;
        int pad = 0;
        if (classType->GetFields().size() > 0) {
          classType->ComputeFieldOffsets();
          hresult << "struct " << classType->GetName() << " {\n";
          for (const auto& field : classType->GetFields()) {
            hresult << "  " << ConvertType(field->type, field->name) << ";\n";
            if (field->padding > 0) {
              hresult << "  uint8_t pad" << pad++ << "[" << field->padding << "];\n";
            }
          }
          hresult << "};\n";
        } else {
          hresult << "struct " << classType->GetName() << ";\n";
        }
        fwrite(hresult.str().c_str(), hresult.str().length(), 1, header_);
      }
    }
  } else if (type->IsEnum()) {
    EnumType* enumType = static_cast<EnumType*>(type);
    result << "types->Make<EnumType>(\"" << enumType->GetName() << "\")";
    if (header_) {
      std::stringstream hresult;
      hresult << "enum class " << enumType->GetName() << " {\n";
      const EnumValueVector& values = enumType->GetValues();
      for (EnumValue const& v : values) {
        hresult << "  " << v.id << " = " << v.value << ",\n";
      }
      hresult << "};\n";
      fwrite(hresult.str().c_str(), hresult.str().length(), 1, header_);
    }
  } else if (type->IsPtr()) {
    PtrType* ptrType = static_cast<PtrType*>(type);
    result << "types->Get" << (type->IsStrongPtr() ? "Strong" : type->IsWeakPtr() ? "Weak" : "Raw")
           << "PtrType(type";
    if (ptrType->GetBaseType()) {
      result << GenType(ptrType->GetBaseType());
    } else {
      result << "nullptr";
    }
    result << ")";
  } else if (type->IsArray()) {
    ArrayType* arrayType = static_cast<ArrayType*>(type);
    result << "types->GetArrayType(type" << GenType(arrayType->GetElementType()) << ", "
           << arrayType->GetNumElements() << ", MemoryLayout::"
           << MemoryLayoutToString(arrayType->GetMemoryLayout()) << ")";
  } else if (type->IsFormalTemplateArg()) {
    FormalTemplateArg* formalTemplateArg = static_cast<FormalTemplateArg*>(type);
    result << "types->GetFormalTemplateArg(\"" << formalTemplateArg->GetName() << "\")";
  } else if (type->IsQualified()) {
    QualifiedType* qualifiedType = static_cast<QualifiedType*>(type);
    result << "types->GetQualifiedType(type" << GenType(qualifiedType->GetBaseType()) << ", "
           << qualifiedType->GetQualifiers() << ")";
  } else if (type->IsUnresolvedScopedType()) {
    auto unresolvedScopedType = static_cast<UnresolvedScopedType*>(type);
    result << "types->GetUnresolvedScopedType(static_cast<FormalTemplateArg*>(type"
           << GenType(unresolvedScopedType->GetBaseType()) << "), \"" << unresolvedScopedType->GetID()
           << "\")";
  } else if (type->IsList()) {
    // This is technically correct, but builds very large list types that aren't used.
    // It also causes the WASM backend to fail with "too many locals".
    const VarVector& vars = static_cast<ListType*>(type)->GetTypes();
    result << "types->GetList(VarVector{";
    for (auto var : vars) {
      result << "std::make_shared<Var>(\"" << var->name << "\", type" << GenType(var->type) << ")";
      if (var != vars.back()) result << ", ";
    }
    result << "})";
    // For now, just emit a placeholder type that will still cause the type IDs in
    // CodeGenLLVM::CreateTypePtr() to match the indices in the type table.
//    result << "types->GetPlaceholder()";
  } else {
    assert(!"unknown type");
    exit(-1);
  }
  result << ";\n";
  fwrite(result.str().c_str(), result.str().length(), 1, file_);
  return id;
}

void GenBindings::Run(const TypeVector& referencedTypes) {
  const TypeVector& types = types_->GetTypes();
  typeMap_.clear();
  typeMap_[nullptr] = 0;
  fprintf(file_, "#include <cstdint>\n");
  fprintf(file_, "#include <ast/ast.h>\n");
  fprintf(file_, "#include <ast/native_class.h>\n");
  fprintf(file_, "#include <ast/symbol.h>\n");
  fprintf(file_, "#include <ast/type.h>\n");
  fprintf(file_, "\n");
  fprintf(file_, "int numReferencedTypesFIXME;");
  fprintf(file_, "namespace Toucan {\n\n");
  fprintf(file_, "Type** InitTypes(SymbolTable* symbols, TypeTable* types, NodeVector* nodes) {\n");
  fprintf(file_, "  ClassType* c;\n");
  fprintf(file_, "  EnumType* e;\n");
  fprintf(file_, "  static Type* typeList[%zu];\n\n", referencedTypes.size());
  fprintf(file_, "  ASTNode** nodeList = new ASTNode*[%d];\n", 1000 /* FIXME num_nodes */);
  fprintf(file_, "  Expr** exprs = reinterpret_cast<Expr**>(nodeList);\n");
  fprintf(file_, "  ArgList** argLists = reinterpret_cast<ArgList**>(nodeList);\n");
  fprintf(file_, "  ExprList** exprLists = reinterpret_cast<ExprList**>(nodeList);\n");
  fprintf(file_, "  Stmt** stmts = reinterpret_cast<Stmt**>(nodeList);\n");
  fprintf(file_, "  Stmts** stmtss = reinterpret_cast<Stmts**>(nodeList);\n");
  fprintf(file_, "  Arg** args = reinterpret_cast<Arg**>(nodeList);\n");
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
    fprintf(header_, "struct Array {\n");
    fprintf(header_, "  void*          ptr;\n");
    fprintf(header_, "  uint32_t       length;\n");
    fprintf(header_, "};\n\n");
  }
  for (auto type : referencedTypes) {
    GenType(type);
  }
  int i = 0;
  // Now that we have defined the types, resolve the references.
  for (auto type : referencedTypes) {
    if (type->IsClass()) {
      GenBindingsForClass(static_cast<ClassType*>(type));
    } else if (type->IsEnum()) {
      GenBindingsForEnum(static_cast<EnumType*>(type));
    }
  }
  for (auto type : referencedTypes) {
    fprintf(file_, "  typeList[%d] = type%d;\n", i++, typeMap_[type]);
  }
  fprintf(file_, "  numReferencedTypesFIXME = %zu;\n", referencedTypes.size());
  fprintf(file_, "  delete[] nodeList;\n");
  fprintf(file_, "  return typeList;\n");
  fprintf(file_, "}\n\n");
  fprintf(file_, "};\n");
  if (header_) { fprintf(header_, "\n};\n}\n"); }
}

void PrintNativeType(std::stringstream& result, Type* type) {
  if (type->IsVoid()) {
    result << "void";
  } else if (type->IsInteger()) {
    IntegerType* integerType = static_cast<IntegerType*>(type);
    result << (integerType->Signed() ? "int" : "uint") << integerType->GetBits() << "_t";
  } else if (type->IsBool()) {
    result << "bool";
  } else if (type->IsFloat()) {
    result << "float";
  } else if (type->IsDouble()) {
    result << "double";
  } else if (type->IsClass()) {
    result << static_cast<ClassType*>(type)->GetName();
  } else if (type->IsEnum()) {
    result << static_cast<EnumType*>(type)->GetName();
  } else if (type->IsRawPtr()) {
    auto baseType = static_cast<RawPtrType*>(type)->GetBaseType();
    baseType = baseType->GetUnqualifiedType();
    if (baseType->IsClass()) {
      PrintNativeType(result, baseType);
      result << "*";
    } else if (baseType->IsUnsizedArray()) {
      result << "Array*";
    } else {
      result << "void*";
    }
  } else if (type->IsStrongPtr() || type->IsWeakPtr()) {
    Type* baseType = static_cast<PtrType*>(type)->GetBaseType()->GetUnqualifiedType();
    if (baseType->IsClass() && static_cast<ClassType*>(baseType)->IsNative()) {
      PrintNativeType(result, baseType);
      result << "*";
    } else {
      result << "Object*";
    }
  } else if (type->IsArray()) {
    ArrayType* arrayType = static_cast<ArrayType*>(type);
    Type*      elementType = arrayType->GetElementType();
    if (elementType->IsVector()) {
      PrintNativeType(result, static_cast<VectorType*>(type)->GetComponentType());
    } else if (elementType->IsMatrix()) {
      PrintNativeType(result, static_cast<MatrixType*>(type)->GetColumnType()->GetComponentType());
    } else {
      PrintNativeType(result, elementType);
    }
    result << "*";
  } else if (type->IsVector()) {
    result << "const ";
    PrintNativeType(result, static_cast<VectorType*>(type)->GetComponentType());
    result << "*";
  } else if (type->IsMatrix()) {
    PrintNativeType(result, static_cast<MatrixType*>(type)->GetColumnType()->GetComponentType());
    result << "*";
  } else if (type->IsQualified()) {
    PrintNativeType(result, static_cast<QualifiedType*>(type)->GetBaseType());
  } else {
    fprintf(stderr, "PrintNativeType():  unknown type \"%s\"\n", type->ToString().c_str());
    exit(-2);
  }
}

void GenBindings::GenBindingsForMethod(Method* method) {
  std::stringstream result;
  int classTypeID = GenType(method->classType);
  result << "  returnType = type" << GenType(method->returnType) << ";\n";
  result << "  m = new Method(0";
  if (method->modifiers & Method::Modifier::Static) { result << " | Method::Modifier::Static"; }
  if (method->modifiers & Method::Modifier::Virtual) { result << " | Method::Modifier::Virtual"; }
  if (method->modifiers & Method::Modifier::DeviceOnly) { result << " | Method::Modifier::DeviceOnly"; }
  if (method->modifiers & Method::Modifier::Vertex) { result << " | Method::Modifier::Vertex"; }
  if (method->modifiers & Method::Modifier::Fragment) { result << " | Method::Modifier::Fragment"; }
  if (method->modifiers & Method::Modifier::Compute) { result << " | Method::Modifier::Compute"; }
  std::string name = method->name;
  result << ", returnType, \"" << name << "\", static_cast<ClassType*>(type" << classTypeID << "));\n";
  const VarVector& argList = method->formalArgList;
  for (int i = 0; i < argList.size(); ++i) {
    Var* var = argList[i].get();
    assert(var->type);
    // Only emit default values for native methods.
    // The DumpAsSourcePass is not fully implemented for all types, and
    // non-native default values are never used at runtime.
    // TODO: fix this through proper constant folding.
    Expr* defaultValue = method->classType->IsNative() ? method->defaultArgs[i] : nullptr;
    int defaultValueId = defaultValue ? sourcePass_.Resolve(defaultValue) : 0;
    result << "  m->AddFormalArg(\"" << var->name << "\", type" << GenType(var->type) << ", ";
    if (defaultValue) {
      result << "exprs[" << defaultValueId << "]";
    } else {
      result << "nullptr";
    }
    result << ");\n";
  }
  result << "  c->AddMethod(m);\n";
  if (method->modifiers & Method::Modifier::Virtual) {
    assert(method->index == 0); // Destructors are the only supported virtual
    result << "  c->SetVTable(0, m);\n";
  }
  bool skipFirst = false;
  if (method->classType->IsNative()) {
    if (header_ && !(method->modifiers & Method::Modifier::DeviceOnly)) {
      std::stringstream hresult;
#if TARGET_OS_IS_WIN
      hresult <<_, "__declspec(dllexport) ";
#endif
      PrintNativeType(hresult, method->returnType);
      hresult << " " << method->GetMangledName() << "(";
      if (method->IsConstructor()) {
        skipFirst = true;
        if (method->classType->IsClassTemplate()) {
          hresult << "int qualifiers, ";
          ClassTemplate* classTemplate = static_cast<ClassTemplate*>(method->classType);
          for (Type* arg : classTemplate->GetFormalTemplateArgs()) {
            FormalTemplateArg* formalTemplateArg = static_cast<FormalTemplateArg*>(arg);
            hresult << "Type* " << formalTemplateArg->GetName();
            if (arg != classTemplate->GetFormalTemplateArgs().back() || !argList.empty()) {
              hresult << ", ";
            }
          }
        }
      }
      for (const std::shared_ptr<Var>& var : argList) {
        if (skipFirst) { skipFirst = false; continue; }
        PrintNativeType(hresult, var->type);
        if (var->name == "this") {
          hresult << " This";
        } else {
          hresult << " " << var->name.c_str();
        }
        if (&var != &argList.back()) { hresult << ", "; }
      }
      hresult << ");\n";
      fwrite(hresult.str().c_str(), hresult.str().length(), 1, header_);
    }
  }
  if ((method->modifiers & (Method::Modifier::Vertex | Method::Modifier::Fragment | Method::Modifier::Compute))) {
  } else if (dumpStmtsAsSource_ && method->stmts) {
    fwrite(result.str().c_str(), result.str().length(), 1, file_);
    result.str(std::string());
    int id = sourcePass_.Resolve(method->stmts);
    result << "  m->stmts = stmtss[" << id << "];\n";
  }
  if (!method->spirv.empty()) {
    result << "  m->spirv = {\n";
    for (uint32_t op : method->spirv) {
      result << op << ", ";
    }
    result << "};\n";
  }
  if (!method->wgsl.empty()) { result << "  m->wgsl = R\"(" << method->wgsl << ")\";\n"; }
  fwrite(result.str().c_str(), result.str().length(), 1, file_);
}

void GenBindings::GenBindingsForClass(ClassType* classType) {
  if (classType->GetTemplate() && classType->IsNative()) { return; }
  std::stringstream result;
  result << "  c = static_cast<ClassType*>(type" << GenType(classType) << ");\n";
  if (classType->IsNative()) {
    result << "  c->SetNative(true);\n";
    result << "  NativeClass::" << classType->GetName() << " = c;\n";
  }
  result << "  c->SetMemoryLayout(MemoryLayout::" <<
    MemoryLayoutToString(classType->GetMemoryLayout()) << ");\n";
  result << "  scope = symbols->PushNewScope();\n";
  result << "  scope->classType = c;\n";
  result << "  c->SetScope(scope);\n";
  if (ClassType* parent = classType->GetParent()) {
    result << "  c->SetParent(static_cast<ClassType*>(type" << GenType(parent) << "));\n";
  }
  for (const auto& i : classType->GetFields()) {
    Field* field = i.get();
    // FIXME: remove this once DumpAsSourcePass is using streams
    fwrite(result.str().c_str(), result.str().length(), 1, file_);
    result.str(std::string());
    int    defaultValueId = field->defaultValue ? sourcePass_.Resolve(field->defaultValue) : 0;
    result << "  c->AddField(\"" << field->name << "\", type" << GenType(field->type) << ", ";
    if (field->defaultValue) {
      result << "exprs[" << defaultValueId << "]";
    } else {
      result << "nullptr";
    }
    result << ");\n";
  }
  fwrite(result.str().c_str(), result.str().length(), 1, file_);
  result.str(std::string());
  for (const auto& m : classType->GetMethods()) {
    Method* method = m.get();
    GenBindingsForMethod(method);
  }
  if (classType->GetScope()) {
    for (const auto& pair : classType->GetScope()->types) {
      result << "  scope->types[\"" << pair.first << "\"] = type" << GenType(pair.second) << ";\n";
    }
  }
  result << "  symbols->PopScope();\n";
  if (!classType->GetTemplate()) {
    result << "  symbols->DefineType(\"" << classType->GetName() << "\", c);\n\n";
  }
  fwrite(result.str().c_str(), result.str().length(), 1, file_);
}

void GenBindings::GenBindingsForEnum(EnumType* enumType) {
  std::stringstream result;
  result << "  e = static_cast<EnumType*>(type" << GenType(enumType) << ");\n";
  for (const EnumValue& v : enumType->GetValues()) {
    result << "  e->Append(\"" << v.id << "\", " << v.value << ");\n";
  }
  result << "  symbols->DefineType(\"" << enumType->GetName() << "\", e);\n\n";
  fwrite(result.str().c_str(), result.str().length(), 1, file_);
}

};  // namespace Toucan
