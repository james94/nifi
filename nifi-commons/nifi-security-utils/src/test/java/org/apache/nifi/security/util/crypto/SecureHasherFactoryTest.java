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
package org.apache.nifi.security.util.crypto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class SecureHasherFactoryTest {

    private static final Argon2SecureHasher DEFAULT_HASHER = new Argon2SecureHasher();

    @Test
    public void testSecureHasherFactoryArgon2() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("NIFI_ARGON2_AES_GCM_256");
        assertEquals(Argon2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryPBKDF2() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("NIFI_PBKDF2_AES_GCM_256");
        assertEquals(PBKDF2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryArgon2ShortName() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("ARGON2");
        assertEquals(Argon2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryArgon2SimilarName() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("ARGON_2");
        assertEquals(Argon2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryFailsUnknownAlgorithmName() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("wrongString");
        assertEquals(Argon2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryDefaultsToArgon2IfLongUnknownAlgorithmName() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("NIFI_UNKNONWN_AES_GCM_256");
        assertEquals(Argon2SecureHasher.class, hasher.getClass());
    }

    @Test
    public void testSecureHasherFactoryEmptyString() {
        SecureHasher hasher = SecureHasherFactory.getSecureHasher("");
        assertEquals(DEFAULT_HASHER.getClass(), hasher.getClass());
    }
}