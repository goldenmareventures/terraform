// commitlint.config.ts

import type { UserConfig } from "@commitlint/types";
import { RuleConfigSeverity } from "@commitlint/types";

const Configuration: UserConfig = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      RuleConfigSeverity.Error,
      "always",
      [
        "build",
        "chore",
        "ci",
        "docs",
        "feat",
        "fix",
        "improvement",
        "perf",
        "refactor",
        "revert",
        "style",
        "test",
        "wip",
      ],
    ],
    "subject-case": [RuleConfigSeverity.Disabled, "always", []],
    "body-max-line-length": [RuleConfigSeverity.Disabled, "always", 0],
  },
};

export default Configuration;
