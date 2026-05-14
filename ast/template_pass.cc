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

#define RESOLVE_OR_DIE(result, value) \
  auto result = Resolve(value); \
  if (!result) return nullptr;

namespace Toucan {

TemplatePass::TemplatePass(NodeVector* nodes) : CopyVisitor(nodes) {}

Result TemplatePass::Visit(ASTClassTemplateInstance* node) {
  RESOLVE_OR_DIE(classTemplate, node->GetClassTemplate());
  RESOLVE_OR_DIE(templateArgs, node->GetTemplateArgs());

#if 0
  for (ClassType* const& i : classTemplate->GetInstances()) {
    if (i->GetTemplateArgs() == templateArgs) { return i; }
  }
  std::string name = classTemplate->GetName();
  auto instance = Make<ClassType>(name);
  instance->SetTemplate(classTemplate);
  instance->SetTemplateArgs(templateArgs);
  classTemplate->AddInstance(instance);
#endif
  ClassType* instance = nullptr;

  return Make<ASTLegacyType>(instance);
}

};  // namespace Toucan
