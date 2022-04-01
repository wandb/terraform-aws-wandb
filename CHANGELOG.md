# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.2.0...v1.3.0) (2022-03-31)


### Features

* Variables to deploy a MySQL 8 database ([#16](https://github.com/wandb/terraform-aws-wandb/issues/16)) ([c261378](https://github.com/wandb/terraform-aws-wandb/commit/c261378ce51a3cec9604d7c4fe22efacb43cef3d))

## [1.2.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.1.0...v1.2.0) (2022-03-15)


### Features

* **kms:** Make kms key customizable ([#15](https://github.com/wandb/terraform-aws-wandb/issues/15)) ([82bad72](https://github.com/wandb/terraform-aws-wandb/commit/82bad728e1d5c13237174262faafad827b0d6d19))

## [1.1.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.0.4...v1.1.0) (2022-02-24)


### Features

* Add kms encryption to eks ([#12](https://github.com/wandb/terraform-aws-wandb/issues/12)) ([71774c7](https://github.com/wandb/terraform-aws-wandb/commit/71774c74e74f223e91f0b2f84ee1c42e2cedc7ba))

### [1.0.4](https://github.com/wandb/terraform-aws-wandb/compare/v1.0.3...v1.0.4) (2022-02-14)


### Bug Fixes

* Separate redis security group rules ([#13](https://github.com/wandb/terraform-aws-wandb/issues/13)) ([71345d6](https://github.com/wandb/terraform-aws-wandb/commit/71345d6b5a6745338883d0927be9019f95a0bffd))

### [1.0.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.0.2...v1.0.3) (2022-02-10)


### Bug Fixes

* Increased desired pod count to match min capacity ([#11](https://github.com/wandb/terraform-aws-wandb/issues/11)) ([0f42428](https://github.com/wandb/terraform-aws-wandb/commit/0f42428e97a5d575310410952535190c361ee92a))

### [1.0.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.0.1...v1.0.2) (2022-02-10)


### Bug Fixes

* Increase node default scale configuration ([#10](https://github.com/wandb/terraform-aws-wandb/issues/10)) ([325120b](https://github.com/wandb/terraform-aws-wandb/commit/325120be5a9c3d9dc9ee41f98f6ac101a4827347))

### [1.0.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.0.0...v1.0.1) (2022-02-10)


### Bug Fixes

* skip elasticache subnet ([#9](https://github.com/wandb/terraform-aws-wandb/issues/9)) ([0cd4ab9](https://github.com/wandb/terraform-aws-wandb/commit/0cd4ab926ac00bd480fb0556a9026ecf8d17d6d2))

## 1.0.0 (2022-02-10)


### Features

* add use internal option ([580f1d6](https://github.com/wandb/terraform-aws-wandb/commit/580f1d6da11d82b5e380cb4a067d123e131eb2a4))


### Bug Fixes

* database subnet group not getting created ([b9bbd59](https://github.com/wandb/terraform-aws-wandb/commit/b9bbd594ed2fc9a8ce7e0877aa81fc654a6ba2d2))


### Reverts

* back to 5.7.12 ([1ca66a9](https://github.com/wandb/terraform-aws-wandb/commit/1ca66a9a85b57390d017eeb08ccdda48dc793f5d))
