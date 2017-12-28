FROM kilna/liquibase
LABEL maintainer="Kilna kilna@kilna.com"

ARG jdbc_driver_version
ENV jdbc_driver_version=${jdbc_driver_version:-5.1.45}\
    jdbc_driver_download_url=https://dev.mysql.com/get/Downloads/Connector-J\
    LIQUIBASE_PORT=${LIQUIBASE_PORT:-3306}\
    LIQUIBASE_CLASSPATH=${LIQUIBASE_CLASSPATH:-/opt/jdbc/mysql-jdbc.jar}\
    LIQUIBASE_DRIVER=${LIQUIBASE_DRIVER:-com.mysql.jdbc.Driver}\
    LIQUIBASE_URL=${LIQUIBASE_URL:-'jdbc:mysql://${HOST}:${PORT}/${DATABASE}'}

COPY test/ /opt/test_liquibase_mysql/
RUN set -x -e -o pipefail;\
    echo "JDBC DRIVER VERSION: $jdbc_driver_version";\
    chmod +x /opt/test_liquibase_mysql/run_test.sh;\
    cd /opt/jdbc;\
    tarfile=mysql-connector-java-${jdbc_driver_version}.tar.gz;\
    curl -SOLs ${jdbc_driver_download_url}/${tarfile};\
    tar -x -f ${tarfile};\
    jarfile=mysql-connector-java-${jdbc_driver_version}-bin.jar;\
    mv mysql-connector-java-${jdbc_driver_version}/${jarfile} ./;\
    rm -rf ${tarfile} mysql-connector-java-${jdbc_driver_version};\
    ln -s ${jarfile} mysql-jdbc.jar;

