/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.nifi.flow;

public enum ComponentType {

    CONNECTION("Connection"),
    PROCESSOR("Processor"),
    PROCESS_GROUP("Process Group"),
    REMOTE_PROCESS_GROUP("Remote Process Group"),
    INPUT_PORT("Input Port"),
    OUTPUT_PORT("Output Port"),
    REMOTE_INPUT_PORT("Remote Input Port"),
    REMOTE_OUTPUT_PORT("Remote Output Port"),
    FUNNEL("Funnel"),
    LABEL("Label"),
    CONTROLLER_SERVICE("Controller Service"),
    REPORTING_TASK("Reporting Task"),
    PARAMETER_CONTEXT("Parameter Context"),
    PARAMETER_PROVIDER("Parameter Provider"),
    TEMPLATE("Template"),
    FLOW_REGISTRY_CLIENT("Flow Registry Client");


    private final String typeName;

    ComponentType(final String typeName) {
        this.typeName = typeName;
    }

    public String getTypeName() {
        return typeName;
    }

    @Override
    public String toString() {
        return typeName;
    }
}
