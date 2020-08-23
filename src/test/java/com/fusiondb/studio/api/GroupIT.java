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

import java.util.List;
import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.http.ContentType.JSON;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static java.util.Arrays.asList;
import static org.apache.http.HttpStatus.SC_NO_CONTENT;
import static org.apache.http.HttpStatus.SC_OK;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class GroupIT {

    @Test
    public void createGroup() {
        final String groupId = "ABC";

        createGroup(groupId);

        // get group
        final ExtractableResponse<Response> groupResponse = getGroup(groupId);

        // check the returned properties
        assertEquals("group" + groupId, groupResponse.jsonPath().getString("groupName"));
    }

    @Test
    public void addGroupManager() {
        final String groupId = "DEF";

        // 1. create a group
        createGroup(groupId);

        // 2. update the group
        final Map<String, Object> requestBody = mapOf(
                Tuple("groupName", "group" + groupId),
                Tuple("managers", new String[] {"admin", "guest"})
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/group/group" + groupId).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the group
        final ExtractableResponse<Response> groupResponse = getGroup(groupId);

        // 4. check the updated group managers
        assertEquals("group" + groupId, groupResponse.jsonPath().getString("groupName"));
        final List<String> actualGroupManagers = groupResponse.jsonPath().getList("managers");
        actualGroupManagers.sort(String::compareTo);
        assertEquals(asList("admin", "guest"),actualGroupManagers );
    }

    @Test
    public void changeGroupManager() {
        final String groupId = "GHI";

        // 1. create a group
        createGroup(groupId);

        // 2. update the group
        final Map<String, Object> requestBody = mapOf(
                Tuple("groupName", "group" + groupId),
                Tuple("managers", new String[] {"guest"})
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/group/group" + groupId).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the group
        final ExtractableResponse<Response> groupResponse = getGroup(groupId);

        // 4. check the updated group managers
        assertEquals("group" + groupId, groupResponse.jsonPath().getString("groupName"));
        assertEquals(asList("guest"), groupResponse.jsonPath().getList("managers"));
    }

    @Test
    public void removeGroupManager() {
        final String groupId = "JKL";

        // 1. create a group
        createGroup(groupId);

        // 2. update the group (add manager)
        Map<String, Object> requestBody = mapOf(
                Tuple("groupName", "group" + groupId),
                Tuple("managers", new String[] {"admin", "guest"})
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/group/group" + groupId).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the group
        ExtractableResponse<Response> groupResponse = getGroup(groupId);

        // 4. check the updated group managers
        assertEquals("group" + groupId, groupResponse.jsonPath().getString("groupName"));
        final List<String> actualGroupManagers = groupResponse.jsonPath().getList("managers");
        actualGroupManagers.sort(String::compareTo);
        assertEquals(asList("admin", "guest"), actualGroupManagers);

        // 5. update the group (remove manager)
        requestBody = mapOf(
                Tuple("groupName", "group" + groupId),
                Tuple("managers", new String[] {"guest"})
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/group/group" + groupId).
        then().
                statusCode(SC_NO_CONTENT);

        // 6. get the group
        groupResponse = getGroup(groupId);

        // 7. check the updated group managers
        assertEquals("group" + groupId, groupResponse.jsonPath().getString("groupName"));
        assertEquals(asList("guest"), groupResponse.jsonPath().getList("managers"));

    }


    private ExtractableResponse<Response> getGroup(final String groupId) {
        return
                given().
                        auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                        contentType(JSON).
                when().
                        get(getApiBaseUri() + "/group/group" + groupId).
                then().
                        statusCode(SC_OK).
                assertThat().
                        body(matchesJsonSchemaInClasspath("group-schema.json")).
                extract();
    }

    private void createGroup(final String groupId, final String... managers) {
        final Map<String, Object> requestBody = mapOf(
                Tuple("groupName", "group" + groupId),
                Tuple("description", "A group named 'group" + groupId + "'"),
                Tuple("metadata", arrayOf(
                        mapOf(
                                Tuple("key", "http://axschema.org/pref/language"),
                                Tuple("value", "en")
                        )
                ))
        );

        if (managers != null && managers.length > 0) {
            requestBody.put("managers", managers);
        }

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                put(getApiBaseUri() + "/group/group" + groupId).
        then().
                statusCode(SC_NO_CONTENT);
    }
}
