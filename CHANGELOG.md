# Changelog

All notable changes to this project will be documented in this file.

## [4.22.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.6...v4.22.0) (2024-07-31)


### Features

* Bump operator image and chart versions ([#250](https://github.com/wandb/terraform-aws-wandb/issues/250)) ([1c60818](https://github.com/wandb/terraform-aws-wandb/commit/1c608185dc6dd68d560d7715060a65fc8719c895))

### [4.21.6](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.5...v4.21.6) (2024-07-24)


### Bug Fixes

* Always let the node role have access to the `default_kms_key` ([#249](https://github.com/wandb/terraform-aws-wandb/issues/249)) ([d8fa06f](https://github.com/wandb/terraform-aws-wandb/commit/d8fa06f89da48443cb9fe0a45f491e5c13bb41cc))

### [4.21.5](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.4...v4.21.5) (2024-07-24)


### Bug Fixes

* Use bucket KMS key arn if provided for W&B managed bucket, always use that key even if empty for customer provided buckets ([#248](https://github.com/wandb/terraform-aws-wandb/issues/248)) ([48131b7](https://github.com/wandb/terraform-aws-wandb/commit/48131b79219071b0a1311bbb5bc468a62c51e266))

### [4.21.4](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.3...v4.21.4) (2024-07-23)


### Bug Fixes

* Yace Yace Yace ([#247](https://github.com/wandb/terraform-aws-wandb/issues/247)) ([cf419bd](https://github.com/wandb/terraform-aws-wandb/commit/cf419bdd8d1a3c3996738bbfe8b292579db59d2f))

### [4.21.3](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.2...v4.21.3) (2024-07-23)


### Bug Fixes

* YACE scoping ([#246](https://github.com/wandb/terraform-aws-wandb/issues/246)) ([47871c8](https://github.com/wandb/terraform-aws-wandb/commit/47871c846c13ed93ffa71b68c8177f0d2d99d7cf))

### [4.21.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.1...v4.21.2) (2024-07-18)


### Bug Fixes

* Condition to create kms.aws_kms_grant.clickhouse was incorrect ([#245](https://github.com/wandb/terraform-aws-wandb/issues/245)) ([78d9be7](https://github.com/wandb/terraform-aws-wandb/commit/78d9be7c0b1126aada5e5df7539ae47ecc6b3368))

### [4.21.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.21.0...v4.21.1) (2024-07-18)


### Bug Fixes

* Don't create KMS key and related resources for CH by default ([#244](https://github.com/wandb/terraform-aws-wandb/issues/244)) ([42d64ba](https://github.com/wandb/terraform-aws-wandb/commit/42d64bae1847a6d26b16bbf46cd341a39389ad0f))

## [4.21.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.20.3...v4.21.0) (2024-07-17)


### Features

* Set up KMS key for clickhouse CMEK and endpoint for PL ([#243](https://github.com/wandb/terraform-aws-wandb/issues/243)) ([1d2fb92](https://github.com/wandb/terraform-aws-wandb/commit/1d2fb921792019b6356e0f89b7c117dda168339a))

### [4.20.3](https://github.com/wandb/terraform-aws-wandb/compare/v4.20.2...v4.20.3) (2024-07-11)


### Bug Fixes

* Naming Conventions ([#241](https://github.com/wandb/terraform-aws-wandb/issues/241)) ([8f20d3e](https://github.com/wandb/terraform-aws-wandb/commit/8f20d3e3a455f348c2f9eb11582ffff592929cf7))

### [4.20.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.20.1...v4.20.2) (2024-07-11)


### Bug Fixes

* AWS VPC CNI revert ([#236](https://github.com/wandb/terraform-aws-wandb/issues/236)) ([7aba491](https://github.com/wandb/terraform-aws-wandb/commit/7aba49119e24ffe68bc7e35dddde127040bfef3e))

### [4.20.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.20.0...v4.20.1) (2024-07-11)


### Bug Fixes

* Pass cloudprovider value to the helm charts ([#240](https://github.com/wandb/terraform-aws-wandb/issues/240)) ([91017d4](https://github.com/wandb/terraform-aws-wandb/commit/91017d4e1d21140be24102b7e5129b4498183749))

## [4.20.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.19.0...v4.20.0) (2024-07-10)


### Features

* Support for encrypting the database and bucket with CMK ([#182](https://github.com/wandb/terraform-aws-wandb/issues/182)) ([bc7c957](https://github.com/wandb/terraform-aws-wandb/commit/bc7c957307a852c94a6f6f4400a215101052fcac))

## [4.19.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.18.0...v4.19.0) (2024-07-09)


### Features

* Resolved yace conflict  ([#239](https://github.com/wandb/terraform-aws-wandb/issues/239)) ([08ed7fa](https://github.com/wandb/terraform-aws-wandb/commit/08ed7faac3c1f18e264feb3f1864d37845520bb2))

## [4.18.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.17.0...v4.18.0) (2024-07-08)


### Features

* Add example tf files for custom vpc, sql, redis, eks ([#208](https://github.com/wandb/terraform-aws-wandb/issues/208)) ([65411c2](https://github.com/wandb/terraform-aws-wandb/commit/65411c2488ee8c9edd744e6e6cc4e203487dea7f))

## [4.17.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.16.0...v4.17.0) (2024-06-26)


### Features

* Fixed yace service account issue ([#234](https://github.com/wandb/terraform-aws-wandb/issues/234)) ([8d290b8](https://github.com/wandb/terraform-aws-wandb/commit/8d290b83f654483823783e8562f9e378172a38a3))

## [4.16.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.15.0...v4.16.0) (2024-06-24)


### Features

* Added private-only traffic feature ([#192](https://github.com/wandb/terraform-aws-wandb/issues/192)) ([1e75812](https://github.com/wandb/terraform-aws-wandb/commit/1e758122e9cb0df34aa2e4ded1368bce5be75278))

## [4.15.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.14.0...v4.15.0) (2024-06-24)


### Features

* Upgraded eks version from 1.27 to 1.28 ([#226](https://github.com/wandb/terraform-aws-wandb/issues/226)) ([4d24df5](https://github.com/wandb/terraform-aws-wandb/commit/4d24df5d85df731c78801e2d625cf16e9d8bc5d3))

## [4.14.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.13.0...v4.14.0) (2024-06-21)


### Features

* Added support s3 endpoints ([#202](https://github.com/wandb/terraform-aws-wandb/issues/202)) ([4ebda49](https://github.com/wandb/terraform-aws-wandb/commit/4ebda4985a0d31df757598c9b3447b6d310e40f8))

## [4.13.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.12.2...v4.13.0) (2024-06-21)


### Features

* Upgraded eks version 1.26 to 1.27 ([#224](https://github.com/wandb/terraform-aws-wandb/issues/224)) ([bb7b99e](https://github.com/wandb/terraform-aws-wandb/commit/bb7b99e95595324c79e1bfaafd2f76d1241b1a8a))

### [4.12.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.12.1...v4.12.2) (2024-06-17)


### Bug Fixes

* Revert resolve conflicts var ([#233](https://github.com/wandb/terraform-aws-wandb/issues/233)) ([778f147](https://github.com/wandb/terraform-aws-wandb/commit/778f147aa9962fde6a74b7d35501ec7dd7abf2a9))

### [4.12.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.12.0...v4.12.1) (2024-06-17)


### Bug Fixes

* Remove white space ([#231](https://github.com/wandb/terraform-aws-wandb/issues/231)) ([974b4f3](https://github.com/wandb/terraform-aws-wandb/commit/974b4f3ec0d01b34cf6d83008c9fe2a0d3d8ee7a))

## [4.12.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.11.0...v4.12.0) (2024-06-17)


### Features

* Added support yace ([#218](https://github.com/wandb/terraform-aws-wandb/issues/218)) ([12e053d](https://github.com/wandb/terraform-aws-wandb/commit/12e053d520f6998689d3bec0352b320a9105ba9e))

## [4.11.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.10.2...v4.11.0) (2024-05-18)


### Features

* Changes to Connect to AWS S3 and KMS using IAM role for EKS service account ([#186](https://github.com/wandb/terraform-aws-wandb/issues/186)) ([a07a45e](https://github.com/wandb/terraform-aws-wandb/commit/a07a45e6d5b979ec2ef8fbb79b63a5d15867da08))

### [4.10.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.10.1...v4.10.2) (2024-05-13)


### Bug Fixes

* Amend standard sizes ([#214](https://github.com/wandb/terraform-aws-wandb/issues/214)) ([a1763f9](https://github.com/wandb/terraform-aws-wandb/commit/a1763f93ef507a99e76940fc8c7a0223b5498ff3))

### [4.10.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.10.0...v4.10.1) (2024-05-08)


### Bug Fixes

* Update to readme ([#213](https://github.com/wandb/terraform-aws-wandb/issues/213)) ([4ab44af](https://github.com/wandb/terraform-aws-wandb/commit/4ab44af5490141f3a50c9cd3589566580862f9a4))

## [4.10.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.9.0...v4.10.0) (2024-05-08)


### Features

* Set default EKS to 1.26; install vpc-cni add-on ([#207](https://github.com/wandb/terraform-aws-wandb/issues/207)) ([0fa5767](https://github.com/wandb/terraform-aws-wandb/commit/0fa5767b47d2612821f4dab3cb589ca3a8fafa2b))

## [4.9.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.8.1...v4.9.0) (2024-04-30)


### Features

* Update default RDS version to 8.0.mysql_aurora.3.05.2 ([#209](https://github.com/wandb/terraform-aws-wandb/issues/209)) ([dd4e1fe](https://github.com/wandb/terraform-aws-wandb/commit/dd4e1fe49a949af461349ee1e5d4bc9306626f90))

### [4.8.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.8.0...v4.8.1) (2024-04-23)


### Bug Fixes

* Update external_dns interval ([#203](https://github.com/wandb/terraform-aws-wandb/issues/203)) ([0a44b43](https://github.com/wandb/terraform-aws-wandb/commit/0a44b43582083832b459822fc4f2af0492f3b4e6))

## [4.8.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.7.2...v4.8.0) (2024-04-23)


### Features

* Dropping support for MySQL 5.7 ([#183](https://github.com/wandb/terraform-aws-wandb/issues/183)) ([0ef5828](https://github.com/wandb/terraform-aws-wandb/commit/0ef5828c8278c7fb585598e48197daf6dcbf0317))

### [4.7.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.7.1...v4.7.2) (2024-04-19)


### Bug Fixes

* Retention Adjustment ([#204](https://github.com/wandb/terraform-aws-wandb/issues/204)) ([3ea7ce1](https://github.com/wandb/terraform-aws-wandb/commit/3ea7ce11b594dafe8b4d59523ca2ad9876b132ce))

### [4.7.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.7.0...v4.7.1) (2024-04-17)


### Bug Fixes

* Adding missing extra_fqdn support for operator that was supported previously ([#197](https://github.com/wandb/terraform-aws-wandb/issues/197)) ([7adf420](https://github.com/wandb/terraform-aws-wandb/commit/7adf4203c2b75447def8483a93d972ed42eb69fc))

## [4.7.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.6.0...v4.7.0) (2024-04-04)


### Features

* Add desired capacity to EKS module ([#200](https://github.com/wandb/terraform-aws-wandb/issues/200)) ([600de97](https://github.com/wandb/terraform-aws-wandb/commit/600de97053aee717d1f2c9718062f3b5af3469f4))

## [4.6.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.5.3...v4.6.0) (2024-04-03)


### Features

* Remove desired_capacity in favor of setting min_capacity ([#198](https://github.com/wandb/terraform-aws-wandb/issues/198)) ([264b448](https://github.com/wandb/terraform-aws-wandb/commit/264b44877a9649796a48e6ff0dff730fdddcee5b))

### [4.5.3](https://github.com/wandb/terraform-aws-wandb/compare/v4.5.2...v4.5.3) (2024-03-22)


### Bug Fixes

* **dev:** Add passthrough for env vars ([#190](https://github.com/wandb/terraform-aws-wandb/issues/190)) ([e944e6d](https://github.com/wandb/terraform-aws-wandb/commit/e944e6d99a248524bd5de3c423b931afa4514dfe))

### [4.5.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.5.1...v4.5.2) (2024-03-21)


### Bug Fixes

* Update readme ([#195](https://github.com/wandb/terraform-aws-wandb/issues/195)) ([bf6b2a7](https://github.com/wandb/terraform-aws-wandb/commit/bf6b2a72acb19f8cc6fceaecc0e8cc0fdffab169))

### [4.5.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.5.0...v4.5.1) (2024-03-21)


### Bug Fixes

* Fix desired_capacity value passing ([#193](https://github.com/wandb/terraform-aws-wandb/issues/193)) ([ebfb34d](https://github.com/wandb/terraform-aws-wandb/commit/ebfb34dcd299e9f3fc79678e97ce4fd9ac7c9629))

## [4.5.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.4.4...v4.5.0) (2024-03-14)


### Features

* **backend:** Make minimum nodes for t-shirts '3' ([#188](https://github.com/wandb/terraform-aws-wandb/issues/188)) ([ae22611](https://github.com/wandb/terraform-aws-wandb/commit/ae2261116a08028763f43955be6d870deb8bdc22))

### [4.4.4](https://github.com/wandb/terraform-aws-wandb/compare/v4.4.3...v4.4.4) (2024-03-11)


### Bug Fixes

* Bump operator chart version ([#187](https://github.com/wandb/terraform-aws-wandb/issues/187)) ([713c1cc](https://github.com/wandb/terraform-aws-wandb/commit/713c1cc233e9ff087fac00e6f9ce83fac2e38eab))

### [4.4.3](https://github.com/wandb/terraform-aws-wandb/compare/v4.4.2...v4.4.3) (2024-03-04)


### Bug Fixes

* Amend tshirt sizes ([#184](https://github.com/wandb/terraform-aws-wandb/issues/184)) ([db11384](https://github.com/wandb/terraform-aws-wandb/commit/db1138436d89e190d783449f1f4300f63b1761b4))

### [4.4.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.4.1...v4.4.2) (2024-02-22)


### Bug Fixes

* Backwards compatibility to avoid node group changes ([#181](https://github.com/wandb/terraform-aws-wandb/issues/181)) ([a1ec409](https://github.com/wandb/terraform-aws-wandb/commit/a1ec40953602f62f15f58f1bf99f40b5d7ce8996))

### [4.4.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.4.0...v4.4.1) (2024-02-21)


### Bug Fixes

* Backwards compatibility for standardized instance sizing in AWS ([#180](https://github.com/wandb/terraform-aws-wandb/issues/180)) ([fa18488](https://github.com/wandb/terraform-aws-wandb/commit/fa184884b917d67580af609dad1991ce4d240586))

## [4.4.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.3.0...v4.4.0) (2024-02-20)


### Features

* BYO VPC ([#168](https://github.com/wandb/terraform-aws-wandb/issues/168)) ([35b1efc](https://github.com/wandb/terraform-aws-wandb/commit/35b1efce3b846bd0355ff4e2ef699e8ebbc1fdc7))

## [4.3.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.2.0...v4.3.0) (2024-02-08)


### Features

* Add standardized instance sizing in AWS ([#172](https://github.com/wandb/terraform-aws-wandb/issues/172)) ([e6b4ab7](https://github.com/wandb/terraform-aws-wandb/commit/e6b4ab7fb33e249d68b145d8c13b4598da4744c3)), closes [#171](https://github.com/wandb/terraform-aws-wandb/issues/171)

## [4.2.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.1.2...v4.2.0) (2024-01-31)


### Features

* PrivateLink support ([#169](https://github.com/wandb/terraform-aws-wandb/issues/169)) ([10cc72f](https://github.com/wandb/terraform-aws-wandb/commit/10cc72ff230b4963272bc13f20010e61562c79ef))

### [4.1.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.1.1...v4.1.2) (2024-01-16)


### Bug Fixes

* Max LB name length ([#166](https://github.com/wandb/terraform-aws-wandb/issues/166)) ([85bd266](https://github.com/wandb/terraform-aws-wandb/commit/85bd266f5f0ce003f2d4e69f796a41df0ff9fb9c))

### [4.1.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.1.0...v4.1.1) (2024-01-11)


### Bug Fixes

* Update redis connection ttl ([#165](https://github.com/wandb/terraform-aws-wandb/issues/165)) ([f236b3b](https://github.com/wandb/terraform-aws-wandb/commit/f236b3b8c5f7d3fcece1a1d302276bde6bdd75d5))

## [4.1.0](https://github.com/wandb/terraform-aws-wandb/compare/v4.0.2...v4.1.0) (2024-01-10)


### Features

* Adding flags to switch between LB ([#159](https://github.com/wandb/terraform-aws-wandb/issues/159)) ([ffa3778](https://github.com/wandb/terraform-aws-wandb/commit/ffa3778fe05da8681a828ce84f3f8291bb8fe5bd))

### [4.0.2](https://github.com/wandb/terraform-aws-wandb/compare/v4.0.1...v4.0.2) (2024-01-09)


### Bug Fixes

* EFS index vs subnet for_each ([#163](https://github.com/wandb/terraform-aws-wandb/issues/163)) ([1e47177](https://github.com/wandb/terraform-aws-wandb/commit/1e47177a0017ef694e7667781111d9ce2d375f2b))

### [4.0.1](https://github.com/wandb/terraform-aws-wandb/compare/v4.0.0...v4.0.1) (2024-01-09)


### Bug Fixes

* Disable gorilla glue tasks ([#161](https://github.com/wandb/terraform-aws-wandb/issues/161)) ([5d24bda](https://github.com/wandb/terraform-aws-wandb/commit/5d24bda4fead8d79b3e06d488ecb824980a3d15b))

## [4.0.0](https://github.com/wandb/terraform-aws-wandb/compare/v3.4.2...v4.0.0) (2024-01-08)


### ⚠ BREAKING CHANGES

* Init operator (#154)

### Features

* Init operator ([#154](https://github.com/wandb/terraform-aws-wandb/issues/154)) ([95def33](https://github.com/wandb/terraform-aws-wandb/commit/95def33db96c55a640fba4df5bdfbcc3a179d8ac))

### [3.4.2](https://github.com/wandb/terraform-aws-wandb/compare/v3.4.1...v3.4.2) (2023-12-07)


### Bug Fixes

* Switch to gp3 volumes on EKS nodes ([#146](https://github.com/wandb/terraform-aws-wandb/issues/146)) ([86dbc7d](https://github.com/wandb/terraform-aws-wandb/commit/86dbc7df0de1aa6d2bc69862770ea67010354c20))

### [3.4.1](https://github.com/wandb/terraform-aws-wandb/compare/v3.4.0...v3.4.1) (2023-12-07)


### Bug Fixes

* Fix private access example ([#155](https://github.com/wandb/terraform-aws-wandb/issues/155)) ([f0745ea](https://github.com/wandb/terraform-aws-wandb/commit/f0745eaf3e2d7111b6becfccac3134b18961e862))

## [3.4.0](https://github.com/wandb/terraform-aws-wandb/compare/v3.3.0...v3.4.0) (2023-11-13)


### Features

* Add support for AWS Secrets Manager ([#151](https://github.com/wandb/terraform-aws-wandb/issues/151)) ([aa64eb1](https://github.com/wandb/terraform-aws-wandb/commit/aa64eb146622132d9b70083094b3c60a728e6038))

## [3.3.0](https://github.com/wandb/terraform-aws-wandb/compare/v3.2.0...v3.3.0) (2023-10-31)


### Features

* Remove vpc-cni EKS add-on in app_eks/main.tf ([#150](https://github.com/wandb/terraform-aws-wandb/issues/150)) ([9f01dde](https://github.com/wandb/terraform-aws-wandb/commit/9f01dde88971487622111e71ec2871b7445b5f57))

## [3.2.0](https://github.com/wandb/terraform-aws-wandb/compare/v3.1.0...v3.2.0) (2023-10-25)


### Features

* **examples:** Adds tf template for bring your own vpc and eks ([#149](https://github.com/wandb/terraform-aws-wandb/issues/149)) ([930ecac](https://github.com/wandb/terraform-aws-wandb/commit/930ecac9034479a620cfcfabe1e14c554c0d4d2c))

## [3.1.0](https://github.com/wandb/terraform-aws-wandb/compare/v3.0.0...v3.1.0) (2023-10-24)


### Features

* external dns ([#148](https://github.com/wandb/terraform-aws-wandb/issues/148)) ([ab45809](https://github.com/wandb/terraform-aws-wandb/commit/ab4580977a323577bc1d1049af7b39c620554a21))

## [3.0.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.8.0...v3.0.0) (2023-10-20)


### ⚠ BREAKING CHANGES

* Deploy aws load balancer controller to clusters (#147)

### Features

* Deploy aws load balancer controller to clusters ([#147](https://github.com/wandb/terraform-aws-wandb/issues/147)) ([90ce430](https://github.com/wandb/terraform-aws-wandb/commit/90ce430022018fdf288cf9cba575af4b59a737c1))

## [2.8.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.7.0...v2.8.0) (2023-09-19)


### Features

* Ouput db creds ([#143](https://github.com/wandb/terraform-aws-wandb/issues/143)) ([23ce843](https://github.com/wandb/terraform-aws-wandb/commit/23ce843e4925b53905cee2f8ca3d43e5c5e55091))

## [2.7.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.6.0...v2.7.0) (2023-09-13)


### Features

* Update to terraform-kubernetes-wandb v1.12.0 ([#142](https://github.com/wandb/terraform-aws-wandb/issues/142)) ([2c40efe](https://github.com/wandb/terraform-aws-wandb/commit/2c40efe56264f9028ff5d2a166b500eadef325dd))

## [2.6.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.5.1...v2.6.0) (2023-09-12)


### Features

* Upgrade kubernetes provider to v2.23.0 ([#141](https://github.com/wandb/terraform-aws-wandb/issues/141)) ([9bd8a87](https://github.com/wandb/terraform-aws-wandb/commit/9bd8a87d49c2f1ccaa067bcb7352b7ff8c6f05bb))

### [2.5.1](https://github.com/wandb/terraform-aws-wandb/compare/v2.5.0...v2.5.1) (2023-09-05)


### Bug Fixes

* Add cloudwatch metrics to policy ([#136](https://github.com/wandb/terraform-aws-wandb/issues/136)) ([be6f070](https://github.com/wandb/terraform-aws-wandb/commit/be6f0705879ca21c776bea43d14561d26fd38edf))

## [2.5.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.4.2...v2.5.0) (2023-09-01)


### Features

* Enable EKS logs ([#134](https://github.com/wandb/terraform-aws-wandb/issues/134)) ([2239119](https://github.com/wandb/terraform-aws-wandb/commit/2239119bd7b2bb0660c25459f20592dfd4016549))

### [2.4.2](https://github.com/wandb/terraform-aws-wandb/compare/v2.4.1...v2.4.2) (2023-08-30)


### Bug Fixes

* SSE-S3 example ([#132](https://github.com/wandb/terraform-aws-wandb/issues/132)) ([627005b](https://github.com/wandb/terraform-aws-wandb/commit/627005b063e1339746dece1d2255ed006ac1b25f))

### [2.4.1](https://github.com/wandb/terraform-aws-wandb/compare/v2.4.0...v2.4.1) (2023-08-29)


### Bug Fixes

* Remove duplicate data statements ([#130](https://github.com/wandb/terraform-aws-wandb/issues/130)) ([ae7e6b2](https://github.com/wandb/terraform-aws-wandb/commit/ae7e6b2b4a038f81ac06fc4a38c7440639a4e66c))

## [2.4.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.3.0...v2.4.0) (2023-08-28)


### Features

* RDS/Aurora Provider Update ([#129](https://github.com/wandb/terraform-aws-wandb/issues/129)) ([394fa56](https://github.com/wandb/terraform-aws-wandb/commit/394fa56586063a5d3cd9c87684f382d4979b3154))

## [2.3.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.2.0...v2.3.0) (2023-08-22)


### Features

* Change default instance type ([#128](https://github.com/wandb/terraform-aws-wandb/issues/128)) ([7353120](https://github.com/wandb/terraform-aws-wandb/commit/735312030f7ef0efac2761254cc00a367194b342))

## [2.2.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.1.0...v2.2.0) (2023-08-16)


### Features

* Update vcp provider ([#120](https://github.com/wandb/terraform-aws-wandb/issues/120)) ([85f9976](https://github.com/wandb/terraform-aws-wandb/commit/85f997655f4119ad1fefe94f07d98f19a9e4ecd9))

## [2.1.0](https://github.com/wandb/terraform-aws-wandb/compare/v2.0.0...v2.1.0) (2023-08-14)


### Features

* Update provider deprecations ([#117](https://github.com/wandb/terraform-aws-wandb/issues/117)) ([e210dc6](https://github.com/wandb/terraform-aws-wandb/commit/e210dc6001af70976a5a307c0883de3bcb0541d7))

## [2.0.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.10...v2.0.0) (2023-07-31)


### ⚠ BREAKING CHANGES

* AWS Provider Upgrade (#116)

### Features

* AWS Provider Upgrade ([#116](https://github.com/wandb/terraform-aws-wandb/issues/116)) ([9d1688f](https://github.com/wandb/terraform-aws-wandb/commit/9d1688f85b9a29b54a9793ad7ef1b24976e98aba))

### [1.16.10](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.9...v1.16.10) (2023-07-28)


### Bug Fixes

* Support performance insights existing kms key arn ([#115](https://github.com/wandb/terraform-aws-wandb/issues/115)) ([9385c01](https://github.com/wandb/terraform-aws-wandb/commit/9385c013cecbe9c3520b717e8386a4a0948aeba8))

### [1.16.9](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.8...v1.16.9) (2023-07-28)


### Bug Fixes

* Add support for out-of-band Performance Insight's being added ([#114](https://github.com/wandb/terraform-aws-wandb/issues/114)) ([210237d](https://github.com/wandb/terraform-aws-wandb/commit/210237d13914514511d0821aadd979cf60b2e047))

### [1.16.8](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.7...v1.16.8) (2023-07-24)


### Bug Fixes

* Resolve duplicate tags issue ([#112](https://github.com/wandb/terraform-aws-wandb/issues/112)) ([d27061e](https://github.com/wandb/terraform-aws-wandb/commit/d27061e2e000643c08c6a8997b4b9e3ace5db576))

### [1.16.6](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.5...v1.16.6) (2023-07-14)


### Bug Fixes

* Remove surreptitious managed_arns [] ([#110](https://github.com/wandb/terraform-aws-wandb/issues/110)) ([4e21ad2](https://github.com/wandb/terraform-aws-wandb/commit/4e21ad2fc50303eaf59351fbce53eefa4f1637f4))

### [1.16.5](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.4...v1.16.5) (2023-07-13)


### Bug Fixes

* Managed arns ([#109](https://github.com/wandb/terraform-aws-wandb/issues/109)) ([701b886](https://github.com/wandb/terraform-aws-wandb/commit/701b886376007ca2726be3811e3e4037e21ee22d))

### [1.16.4](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.3...v1.16.4) (2023-07-13)


### Bug Fixes

* Bridge for missing bucket key arn ([#108](https://github.com/wandb/terraform-aws-wandb/issues/108)) ([7ae06b1](https://github.com/wandb/terraform-aws-wandb/commit/7ae06b1bab8111e433bbaecabc416c77a1b445d5))

### [1.16.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.2...v1.16.3) (2023-07-13)


### Bug Fixes

* Change policy names ([#107](https://github.com/wandb/terraform-aws-wandb/issues/107)) ([cfc5083](https://github.com/wandb/terraform-aws-wandb/commit/cfc50832fa35d9d6b0c5068e092b1bd4f0b5203e))

### [1.16.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.16.1...v1.16.2) (2023-07-13)


### Bug Fixes

* Removed inline policies from eks_app ([#106](https://github.com/wandb/terraform-aws-wandb/issues/106)) ([bb34c7b](https://github.com/wandb/terraform-aws-wandb/commit/bb34c7b94b487edb09f71dfb0715ec4b7740dc19))

## [1.16.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.7...v1.16.0) (2023-07-11)


### Features

* Support team level buckets by using the direct node role ARN ([#100](https://github.com/wandb/terraform-aws-wandb/issues/100)) ([e09d5d2](https://github.com/wandb/terraform-aws-wandb/commit/e09d5d282a8eba98c5c5c5ec2020c7254d2834b0))

### [1.15.7](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.6...v1.15.7) (2023-07-07)


### Bug Fixes

* Add new AWS Aurora RDS config parameters ([#91](https://github.com/wandb/terraform-aws-wandb/issues/91)) ([9e47438](https://github.com/wandb/terraform-aws-wandb/commit/9e47438c0f9981a0a6ca1e3f445df6f7a6a342eb))

### [1.15.6](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.5...v1.15.6) (2023-06-27)


### Bug Fixes

* Set SG rules for HTTPS only ([#96](https://github.com/wandb/terraform-aws-wandb/issues/96)) ([d842560](https://github.com/wandb/terraform-aws-wandb/commit/d8425608bc1f03d3e7c1cf0cbb1e914c8f90587e))

### [1.15.5](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.4...v1.15.5) (2023-06-22)


### Bug Fixes

* Add lifecycle rules to SG definitions to allow SG deletion ([#94](https://github.com/wandb/terraform-aws-wandb/issues/94)) ([3000b24](https://github.com/wandb/terraform-aws-wandb/commit/3000b244e150870e89db651d8f16ef34fe0a262a))

### [1.15.4](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.3...v1.15.4) (2023-06-21)


### Bug Fixes

* Put rules for inbound HTTP/HTTPS into their own security groups ([#93](https://github.com/wandb/terraform-aws-wandb/issues/93)) ([66c8e7d](https://github.com/wandb/terraform-aws-wandb/commit/66c8e7d6061b7f5f92cae0f559c8b3fc51b122e2))

### [1.15.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.2...v1.15.3) (2023-06-21)


### Bug Fixes

* Revert separate HTTP and HTTPS rule creation ([#92](https://github.com/wandb/terraform-aws-wandb/issues/92)) ([dae476a](https://github.com/wandb/terraform-aws-wandb/commit/dae476a270819df99c62b81e7bac9f822d770941))

### [1.15.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.1...v1.15.2) (2023-06-21)


### Bug Fixes

* Separate HTTP and HTTPS rule creation ([#90](https://github.com/wandb/terraform-aws-wandb/issues/90)) ([98b0159](https://github.com/wandb/terraform-aws-wandb/commit/98b0159d30e204dfa3c9345c0ea3777baa0361d0))

### [1.15.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.15.0...v1.15.1) (2023-05-26)


### Bug Fixes

* ToSet required here ([#86](https://github.com/wandb/terraform-aws-wandb/issues/86)) ([0638e75](https://github.com/wandb/terraform-aws-wandb/commit/0638e75b78b28317c9e13576dd9d235608d17515))

## [1.15.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.14.1...v1.15.0) (2023-05-19)


### Features

* Output cluster node role ([#78](https://github.com/wandb/terraform-aws-wandb/issues/78)) ([248e44d](https://github.com/wandb/terraform-aws-wandb/commit/248e44df548611e2be3d09d55ff8dae7c82a7729))

### [1.14.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.14.0...v1.14.1) (2023-05-18)


### Bug Fixes

* Bucket creation ([#83](https://github.com/wandb/terraform-aws-wandb/issues/83)) ([98baa19](https://github.com/wandb/terraform-aws-wandb/commit/98baa190007ed9c97f31892c4ecb30c4a1d8015f))

## [1.14.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.13.3...v1.14.0) (2023-05-18)


### Features

* Add redis node type as variable ([#84](https://github.com/wandb/terraform-aws-wandb/issues/84)) ([fee5a85](https://github.com/wandb/terraform-aws-wandb/commit/fee5a85e4f7a76226a879e03aeb961587545e8fb))


### Bug Fixes

* Create LICENSE ([#79](https://github.com/wandb/terraform-aws-wandb/issues/79)) ([8a074ab](https://github.com/wandb/terraform-aws-wandb/commit/8a074ab46acc28ebdc4d87c704352a2eb0d4242e))

### [1.13.3](https://github.com/wandb/terraform-aws-wandb/compare/v1.13.2...v1.13.3) (2023-05-17)


### Bug Fixes

* Always use internal queue ([#81](https://github.com/wandb/terraform-aws-wandb/issues/81)) ([0e878dd](https://github.com/wandb/terraform-aws-wandb/commit/0e878dd9721a5e270a7916934174e67455091221))

### [1.13.2](https://github.com/wandb/terraform-aws-wandb/compare/v1.13.1...v1.13.2) (2023-05-16)


### Bug Fixes

* Bucket creation ([#80](https://github.com/wandb/terraform-aws-wandb/issues/80)) ([6a2be55](https://github.com/wandb/terraform-aws-wandb/commit/6a2be551765d6c43cc92ac849a112e7adaf7b5b6))

### [1.13.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.13.0...v1.13.1) (2023-05-16)


### Bug Fixes

* Always create bucket ([#73](https://github.com/wandb/terraform-aws-wandb/issues/73)) ([f03b9c4](https://github.com/wandb/terraform-aws-wandb/commit/f03b9c4a98972fa2584f4ea547e5385910892207))

## [1.13.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.12.1...v1.13.0) (2023-03-22)


### Features

* Support for extra fqdn ([#67](https://github.com/wandb/terraform-aws-wandb/issues/67)) ([55c1b2c](https://github.com/wandb/terraform-aws-wandb/commit/55c1b2c5781ee7c569609e1fc8f56c6e05e447fb))

### [1.12.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.12.0...v1.12.1) (2023-03-22)


### Bug Fixes

* KMS least access privilege ([#68](https://github.com/wandb/terraform-aws-wandb/issues/68)) ([ef6e85a](https://github.com/wandb/terraform-aws-wandb/commit/ef6e85ad5fd8d3818e1e3c2c54d64a2cc92ab7a0))

## [1.12.0](https://github.com/wandb/terraform-aws-wandb/compare/v1.11.1...v1.12.0) (2023-03-08)


### Features

* DB migration support ([#64](https://github.com/wandb/terraform-aws-wandb/issues/64)) ([d8b9634](https://github.com/wandb/terraform-aws-wandb/commit/d8b96342e2c752783e398c0e3b4a9fc8e87d1eca))

### [1.11.1](https://github.com/wandb/terraform-aws-wandb/compare/v1.11.0...v1.11.1) (2023-03-06)


### Bug Fixes

* Set MySQL default version to 8.0.mysql_aurora.3.05.2 ([#63](https://github.com/wandb/terraform-aws-wandb/issues/63)) ([7340b1f](https://github.com/wandb/terraform-aws-wandb/commit/7340b1f8761c4a0edaefbd22e4c4fd61bb8f16af))

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
