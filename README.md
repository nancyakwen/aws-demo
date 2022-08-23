# Managing a MySQL for RDS Database in a private VPC

This sample application runs SQL queries on a MySQL database. It uses a private VPC to connect to an Amazon Relational Database Service (Amazon RDS) database. The application also uses AWS Secrets Manager and AWS X-Ray.

![Architecture](/sample-apps/rds-mysql/images/sample-rdsmysql.png)

The function takes a event with the following structure:

```
{
  "query": "CREATE TABLE events ( id varchar(255), title varchar(255), timestamp BIGINT, entries varchar(32765));"
}
```

The function executes the query and logs the output.

To deploy run [setup.sh](./setup.sh).