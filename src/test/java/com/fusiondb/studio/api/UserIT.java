/*
 * Fusion Studio API - API for Fusion Studio
 * Copyright © 2017 Evolved Binary (tech@evolvedbinary.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.fusiondb.studio.api;

import io.restassured.response.ExtractableResponse;
import io.restassured.response.Response;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.http.ContentType.JSON;
import static org.apache.http.HttpStatus.*;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class UserIT {

    @Test
    public void createUser() {
        final String userId = "123";

        createUser(userId);

        // get user
        final ExtractableResponse<Response> userResponse = getUser(userId);

        // check they are enabled
        assertTrue(userResponse.jsonPath().getBoolean("enabled"));
    }

    @Test
    public void createUserDisabled() {
        final String userId = "456";

        createUser(userId, true);

        // get user
        final ExtractableResponse<Response> userResponse = getUser(userId);

        // check they are disabled
        assertFalse(userResponse.jsonPath().getBoolean("enabled"));
    }

    @Test
    public void disableUser() {
        final String userId = "789";

        // 1. create the user
        createUser(userId);

        // 2. update the user
        final Map<String, Object> requestBody = mapOf(
                Tuple("userName", "user" + userId),
                Tuple("enabled", false)
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/user/user" + userId).
        then().
                statusCode(SC_NO_CONTENT);

        // get user
        final ExtractableResponse<Response> userResponse = getUser(userId);

        // check they are now disabled
        assertFalse(userResponse.jsonPath().getBoolean("enabled"));
    }

    private ExtractableResponse<Response> getUser(final String userId) {
        return
            given().
                    auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                    contentType(JSON).
            when().
                    get(getApiBaseUri() + "/user/user" + userId).
            then().
                    statusCode(SC_OK)
            .extract();
    }

    private void createUser(final String userId) {
        createUser(userId,false);
    }

    private void createUser(final String userId, final boolean disabled) {
        final Map<String, Object> requestBody = mapOf(
                Tuple("userName", "user" + userId),
                Tuple("password", "user" + userId),
                Tuple("metadata", arrayOf(
                        mapOf(
                                Tuple("key", "http://axschema.org/namePerson"),
                                Tuple("value", "User " + userId)
                        ),
                        mapOf(
                                Tuple("key", "http://axschema.org/pref/language"),
                                Tuple("value", "en")
                        )
                ))
        );

        if (disabled) {
            requestBody.put("enabled", false);
        }

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/user/user" + userId).
        then().
                statusCode(SC_NO_CONTENT);
    }
}
