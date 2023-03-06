# Changelog

All notable changes to this project will be documented in this file.

### [1.11.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.11.0...v1.11.1) (2023-03-06)


### Bug Fixes

* Set MySQL default version to 8.0.mysql_aurora.3.03.0 ([#63](https://github.com/wandb/terraform-aws-wandb/issues/63)) ([7340b1f](https://github.com/wandb/terraform-aws-wandb/commit/7340b1f8761c4a0edaefbd22e4c4fd61bb8f16af))

## [1.11.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.5...v1.11.0) (2023-02-28)


### Features

* Add module for Secure Storage Connector ([#52](https://github.com/wandb/terraform-aws-wandb/issues/52)) ([8f07c99](https://github.com/wandb/terraform-aws-wandb/commit/8f07c9972ff503ee6169060422a00cbbb0d013e3))

### [1.10.5](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.4...v1.10.5) (2023-02-25)


### Bug Fixes

* Security ElastiCache.1 ([#60](https://github.com/wandb/terraform-aws-wandb/issues/60)) ([c5d7fe8](https://github.com/wandb/terraform-aws-wandb/commit/c5d7fe81352e32f8e3fcfe364791bf2397be4544))

### [1.10.4](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.3...v1.10.4) (2023-02-24)


### Bug Fixes

* Update IMDsv2 policy name and format ([#59](https://github.com/wandb/terraform-aws-wandb/issues/59)) ([b1db83f](https://github.com/wandb/terraform-aws-wandb/commit/b1db83f3b71d3a78480fd6b2b6cfeabed71e37fc))

### [1.10.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.2...v1.10.3) (2023-02-24)


### Bug Fixes

* Update metadata hop limit and fix race condition ([#58](https://github.com/wandb/terraform-aws-wandb/issues/58)) ([96e8ddb](https://github.com/wandb/terraform-aws-wandb/commit/96e8ddb8834c6e26bf58d5b2049c1dedd4702df1))

### [1.10.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.1...v1.10.2) (2023-02-24)


### Bug Fixes

* Enable IMDsv2 ([#57](https://github.com/wandb/terraform-aws-wandb/issues/57)) ([3719069](https://github.com/wandb/terraform-aws-wandb/commit/3719069a5b575cc4e12a7568648be80def8f6bef))

### [1.10.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.10.0...v1.10.1) (2023-02-23)


### Bug Fixes

* Deploy the aws-ebs-csi-driver so 1.23 k8s upgrade is possible ([#56](https://github.com/wandb/terraform-aws-wandb/issues/56)) ([f6c7ced](https://github.com/wandb/terraform-aws-wandb/commit/f6c7ceda586acaa59948d5078afcf7fa393202d6))

## [1.10.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.9.0...v1.10.0) (2023-02-22)


### Features

* Force ebs encrypt ([#55](https://github.com/wandb/terraform-aws-wandb/issues/55)) ([d43f8c7](https://github.com/wandb/terraform-aws-wandb/commit/d43f8c7dfb3e971c5548d0f4a54f6aec585986ee))

## [1.9.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.8.0...v1.9.0) (2023-02-22)


### Features

* Least Access Privilege iam BYOB ([#50](https://github.com/wandb/terraform-aws-wandb/issues/50)) ([3ed0179](https://github.com/wandb/terraform-aws-wandb/commit/3ed01795723ba10b9ce3a7164644694d6a1181f2))

## [1.8.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.7.0...v1.8.0) (2023-02-16)


### Features

* New kubernetes_instance_types variable ([#51](https://github.com/wandb/terraform-aws-wandb/issues/51)) ([0a35ef0](https://github.com/wandb/terraform-aws-wandb/commit/0a35ef03f666775359eead0d2ace248e57405d6c))

## [1.7.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.6.0...v1.7.0) (2023-02-16)


### Features

* Allow custom EKS policies ([#46](https://github.com/wandb/terraform-aws-wandb/issues/46)) ([89f70cc](https://github.com/wandb/terraform-aws-wandb/commit/89f70cc89b351d15f2b6b6b17a6e06010f6e3efb))

## [1.6.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.5.3...v1.6.0) (2022-09-27)


### Features

* Disable auto scaling for database ([#38](https://github.com/wandb/terraform-aws-wandb/issues/38)) ([8686fed](https://github.com/wandb/terraform-aws-wandb/commit/8686fed4fbba9e5de52368e8b5ef40d369aa0499))

### [1.5.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.5.2...v1.5.3) (2022-07-30)


### Bug Fixes

* Add regex check for db version ([#33](https://github.com/wandb/terraform-aws-wandb/issues/33)) ([124d988](https://github.com/wandb/terraform-aws-wandb/commit/124d988f4bccd94a93d6cfafa5553fb143d94de9))

### [1.5.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.5.1...v1.5.2) (2022-07-28)


### Bug Fixes

* Add sort buffer size parameter ([#26](https://github.com/wandb/terraform-aws-wandb/issues/26)) ([819a5c8](https://github.com/wandb/terraform-aws-wandb/commit/819a5c85f2fdd48c14a2320f58ed48d8f30df4bf))

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
