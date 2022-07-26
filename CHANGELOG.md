# Changelog

All notable changes to this project will be documented in this file.

### [1.5.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.5.0...v1.5.1) (2022-06-07)


### Bug Fixes

* Makes bucket kms key conditional ([#29](https://github.com/wandb/terraform-aws-wandb/issues/29)) ([163625e](https://github.com/wandb/terraform-aws-wandb/commit/163625ea9015bf3eb372461d449f7553abf5ca5a))

## [1.5.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.4.1...v1.5.0) (2022-05-27)


### Features

* Option to provide an database snapshot ([#27](https://github.com/wandb/terraform-aws-wandb/issues/27)) ([46deb1b](https://github.com/wandb/terraform-aws-wandb/commit/46deb1bc72df06f96a834ad604e06b5dfea2b4ce))

### [1.4.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.4.0...v1.4.1) (2022-04-15)


### Bug Fixes

* Add cloudwatch policy ([#21](https://github.com/wandb/terraform-aws-wandb/issues/21)) ([3f73a21](https://github.com/wandb/terraform-aws-wandb/commit/3f73a21bdc757e3ccd1cfe0c5b2165440755ce63))

## [1.4.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.3.1...v1.4.0) (2022-04-05)


### Features

* Default mode to deploy mysql 8 ([#20](https://github.com/wandb/terraform-aws-wandb/issues/20)) ([b0d5c84](https://github.com/wandb/terraform-aws-wandb/commit/b0d5c84858b4890432bf3f1ca830a2109dfe7e48))

### [1.3.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.3.0...v1.3.1) (2022-04-04)


### Bug Fixes

* Variable for setting database instance type ([#19](https://github.com/wandb/terraform-aws-wandb/issues/19)) ([e99d4ba](https://github.com/wandb/terraform-aws-wandb/commit/e99d4ba0e08538a5f399bb536f98dba044e210db))

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
