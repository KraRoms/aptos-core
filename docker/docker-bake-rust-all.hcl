# This is a docker bake file in HCL syntax.
# It provides a high-level mechenanism to build multiple dockerfiles in one shot.
# Check https://crazymax.dev/docker-allhands2-buildx-bake and https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition for an intro.


variable "BUILD_DATE" {}

// this is the short GIT_SHA1 (8 chars). Tagging our docker images with that one is kinda deprecated and we might remove this in future.
variable "GIT_REV" {}
// this is the full GIT_SHA1 - let's use that as primary identify going forward
variable "GIT_SHA1" {}

variable "AWS_ECR_ACCOUNT_NUM" {}

variable "ecr_base" {
  default = "${AWS_ECR_ACCOUNT_NUM}.dkr.ecr.us-west-2.amazonaws.com/aptos"
}

variable "gh_image_cache" {
  default = "ghcr.io/aptos-labs/aptos-core/image-cache"
}

group "all" {
  targets = [
    "validator",
    "indexer",
    "safety-rules",
    "tools",
    "init",
    "txn-emitter",
    "faucet",
    "forge",
  ]
}

target "_common" {
  dockerfile = "docker/rust-all.Dockerfile"
  context    = "."
  cache-from = ["type=registry,ref=${gh_image_cache}"]
  cache-to   = ["type=registry,ref=${gh_image_cache},mode=max"]
  labels = {
    "org.label-schema.schema-version" = "1.0",
    "org.label-schema.build-date"     = "${BUILD_DATE}"
    "org.label-schema.vcs-ref"        = "${GIT_REV}"
  }
  args = {
    IMAGE_TARGETS         = "release"
  }
}

target "validator" {
  inherits = ["_common"]
  target   = "validator"
  tags     = generate_tags("validator")
}

target "indexer" {
  inherits = ["_common"]
  target   = "indexer"
  tags     = generate_tags("indexer")
}

target "safety-rules" {
  inherits = ["_common"]
  target   = "safety-rules"
  tags     = generate_tags("validator_tcb")
}

target "tools" {
  inherits = ["_common"]
  target   = "tools"
  tags     = generate_tags("tools")
}

target "init" {
  inherits = ["_common"]
  target   = "init"
  tags     = generate_tags("init")
}

target "txn-emitter" {
  inherits = ["_common"]
  target   = "txn-emitter"
  tags     = generate_tags("txn-emitter")
}

target "faucet" {
  inherits = ["_common"]
  target   = "faucet"
  tags     = generate_tags("faucet")
  args = {
    IMAGE_TARGETS = "test"
  }
}

target "forge" {
  inherits = ["_common"]
  target   = "forge"
  tags     = generate_tags("forge")
  args = {
    IMAGE_TARGETS = "test"
  }
}

// function "generate_cache_from" {
//   params = [target]
//   cache-from = ["type=registry,ref=${gh_image_cache}/${target}"]
// }

// function "generate_cache_to" {
//   params = [target]
//   cache-to = ["type=registry,ref=${gh_image_cache}/${target},mode=max"]
// }

function "generate_tags" {
  params = [target]
  result = ["${ecr_base}/${target}:dev_${GIT_REV}", "${ecr_base}/${target}:${GIT_REV}", "${ecr_base}/${target}:${GIT_SHA1}"]
}