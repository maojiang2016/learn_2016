#!/bin/bash

export JAVA_HOME=/opt/j2sdk
export M2_HOME=/opt/maven
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH

## constant
BUILD_ROOT=/data/build/jzc-wechat-server
SOURCE_ROOT=$BUILD_ROOT/source
DEPLOY_ROOT=$BUILD_ROOT/target
PROJECT_JAR=jzc-wechat-1.0.0-SNAPSHOT.jar

## compile
cd $SOURCE_ROOT
svn up
mvn clean
mvn package
mvn dependency:copy-dependencies

## package
svn up $DEPLOY_ROOT
for ii in `diff $SOURCE_ROOT/target/dependency/ $DEPLOY_ROOT/WEB-INF/lib/|grep "Only"|grep "WEB-INF"|grep "jar"|grep -v "junit"|grep -v "$PROJECT_JAR"|awk '{print $NF}'`; do
    rm -rf $DEPLOY_ROOT/WEB-INF/lib/$ii
done

cd $DEPLOY_ROOT/WEB-INF/lib
\cp -rf $SOURCE_ROOT/target/$PROJECT_JAR ./
for ii in `ls $SOURCE_ROOT/target/dependency/*.jar|grep -v "jetty"|grep -v "javax.servlet-api"|grep -v "junit"`; do
    \cp -rf $ii ./
done

\cp -rf $SOURCE_ROOT/src/main/web/WEB-INF/web.xml $DEPLOY_ROOT/WEB-INF/

for ii in `svn status $DEPLOY_ROOT|awk '{if($1 == "?") print $NF}'`; do
    svn add $ii
done
for ii in `svn status $DEPLOY_ROOT|awk '{if($1 == "!") print $NF}'`; do
    svn del $ii
done

\cp -rf $SOURCE_ROOT/src/main/web/WEB-INF/web.xml $DEPLOY_ROOT/WEB-INF/

svn ci -m"commit build result" $DEPLOY_ROOT