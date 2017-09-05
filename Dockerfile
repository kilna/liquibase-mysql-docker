FROM kilna/liquibase

ARG mysql_jdbc_version=5.1.44
ARG mysql_jdbc_download_url=https://dev.mysql.com/get/Downloads/Connector-J

ENV LIQUIBASE_PORT=${LIQUIBASE_PORT:-3306}\
    LIQUIBASE_CLASSPATH=${LIQUIBASE_CLASSPATH:-/opt/jdbc/mysql-jdbc.jar}\
    LIQUIBASE_DRIVER=${LIQUIBASE_DRIVER:-com.mysql.jdbc.Driver}\
    LIQUIBASE_URL=${LIQUIBASE_URL:-'jdbc:mysql://${HOST}:${PORT}/${DATABASE}'}

COPY test/ /opt/test/
RUN set -e -o pipefail;\
    cd /opt/jdbc;\
    tarfile=mysql-connector-java-${mysql_jdbc_version}.tar.gz;\
    curl -SOLs ${mysql_jdbc_download_url}/${tarfile};\
    tar -x -f ${tarfile};\
    jarfile=mysql-connector-java-${mysql_jdbc_version}-bin.jar;\
    mv mysql-connector-java-${mysql_jdbc_version}/${jarfile} ./;\
    rm -rf ${tarfile} mysql-connector-java-${mysql_jdbc_version};\
    ln -s ${jarfile} mysql-jdbc.jar;\
    set | grep -F LIQUIBASE_

