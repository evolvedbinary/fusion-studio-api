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

import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.fusiondb.studio.api.API.getApiBaseUri;
import static io.restassured.RestAssured.when;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static org.apache.http.HttpStatus.SC_OK;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class VersionIT {

    @Test
    public void getVersion() {
        when().
                get(getApiBaseUri() + "/version").
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("version-schema.json"));
    }

    @Test
    public void existCompatibleVersionIsNotNull() {
        final Object existDbJson = when().
                get(getApiBaseUri() + "/version").
                then().
                statusCode(SC_OK).
                assertThat().
                body(matchesJsonSchemaInClasspath("version-schema.json"))
                .extract()
                .jsonPath().get("server.exist-db");
        assertNotNull(existDbJson);
        assertTrue(existDbJson instanceof Map);

        final Map<String, Object> map = (Map<String, Object>) existDbJson;
        if (map.containsKey("compatible-version")) {
            assertNotNull(map.get("compatible-version"));
        }
    }
}
