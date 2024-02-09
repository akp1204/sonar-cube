[
  {
    "name": "sonarcube-container",
    "image": "sonarqube:lts",
    "cpu": 1024,
    "memory": 2048,
    "networkMode": "awsvpc",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/sonarcube-ecs-task",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
    },
	"environment": [
          {
            "name": "SONAR_JDBC_USERNAME",
            "value": "${sonar_db_username}"
          },
		  {
            "name": "SONAR_JDBC_PASSWORD",
            "value": "${sonar_db_password}"
          },
		  {
            "name": "SONAR_JDBC_PASSWORD",
            "value": "jdbc:postgresql://${aws_rds_cluster.aurora_db.endpoint}/${sonar_db_name}?sslmode=require"
          }
        ],
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000
      }
    ]
  }
]
