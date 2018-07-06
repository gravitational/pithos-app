# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


all: kubernetes-cassandra.jar

# build the cassandra seed provider
kubernetes-cassandra.jar:
	@echo "Building kubernetes-cassandra.jar"
	docker run -v ${CURDIR}/.m2:/root/.m2 -v ${CURDIR}/java:/usr/src/app \
		maven:3-jdk-8-onbuild-alpine mvn clean package
	cp java/target/*jar-with-dependencies.jar rootfs/kubernetes-cassandra.jar
