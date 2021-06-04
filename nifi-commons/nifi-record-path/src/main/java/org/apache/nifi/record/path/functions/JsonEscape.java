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

package org.apache.nifi.record.path.functions;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.nifi.record.path.FieldValue;
import org.apache.nifi.record.path.RecordPathEvaluationContext;
import org.apache.nifi.record.path.StandardFieldValue;
import org.apache.nifi.record.path.exception.RecordPathException;
import org.apache.nifi.record.path.paths.RecordPathSegment;
import org.apache.nifi.serialization.record.Record;
import org.apache.nifi.serialization.record.RecordFieldType;
import org.apache.nifi.serialization.record.util.DataTypeUtils;

import java.util.stream.Stream;

public class JsonEscape extends RecordPathSegment {
    private final RecordPathSegment recordPath;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public JsonEscape(final RecordPathSegment recordPath, final boolean absolute) {
        super("jsonEscape", null, absolute);
        this.recordPath = recordPath;
    }

    @Override
    public Stream<FieldValue> evaluate(final RecordPathEvaluationContext context) {
        final Stream<FieldValue> fieldValues = recordPath.evaluate(context);
        return fieldValues.filter(fv -> fv.getValue() != null)
                .map(fv -> {
                    Object value = fv.getValue();
                    if (value == null) {
                        return new StandardFieldValue(null, fv.getField(), fv.getParent().orElse(null));
                    } else {
                        if (value instanceof Record) {
                            value = DataTypeUtils.convertRecordFieldtoObject(value, RecordFieldType.RECORD.getDataType());
                        }

                        try {
                            return new StandardFieldValue(objectMapper.writeValueAsString(value), fv.getField(), fv.getParent().orElse(null));
                        } catch (JsonProcessingException e) {
                            throw new RecordPathException("Unable to serialise Record Path value as JSON String", e);
                        }
                    }
                });
    }

}
