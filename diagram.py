from diagrams import Cluster, Diagram
from diagrams.aws.compute import EKS
from diagrams.aws.network import Route53, ALB
from diagrams.aws.database import Aurora, AuroraInstance
from diagrams.aws.storage import S3
from diagrams.aws.integration import SQS
from diagrams.aws.security import ACM, KMS
from diagrams.aws.network import VPC

graph_attr = {
    "bgcolor": "transparent"
}

with Diagram("terraform-aws-wandb", show=False, graph_attr=graph_attr):
    dns = Route53("DNS")

    with Cluster("main.tf"):
        cert = ACM("aws-modules/acm")

        with Cluster('module/networking'):
            vpc = VPC('VPC')

        with Cluster("module/app_lb"):
            alb = ALB("App LB")

        with Cluster("module/database"):
            db = Aurora("Cluster")
            db_instance = AuroraInstance("MySQL 5.7")

        with Cluster("module/kms"):
            kms = KMS('KMS')

        with Cluster("module/app_eks"):
            cluster = EKS("Cluster")

        with Cluster("module/file_storage"):
            bucket = S3('Files')
            bucket_queue = SQS("Files Queue")

    cert >> dns >> vpc >> alb
    cert >> alb >> cluster

    kms >> bucket
    kms >> db
    kms >> cluster

    cluster >> db >> db_instance
    cluster >> bucket >> bucket_queue
    cluster >> bucket_queue

