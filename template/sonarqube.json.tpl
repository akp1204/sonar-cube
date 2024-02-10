[
  {
    "name": "${app_name}-container",
    "image": "${app_name}:lts",
    "cpu": 1024,
    "memory": 2048,
    "networkMode": "awsvpc",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/${app_name}-ecs-task",
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
            "name": "SONAR_ENDPOINT",
            "value": "jdbc:postgresql://${sonar_endpoint}/${sonar_db_name}?sslmode=require"
          }
        ],
         "command" : [
    "-Dsonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false"
  ],
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000
      }
    ]
  }
]
