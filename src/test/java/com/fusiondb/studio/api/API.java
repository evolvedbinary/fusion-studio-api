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

import java.util.function.Function;

public class API {

    /**
     * Default Host for FusionDB Server
     */
    public static String DEFAULT_HOST = "localhost";

    /**
     * Default Port for FusionDB Server
     */
    public static int DEFAULT_PORT = 4059;

    /**
     * Default API Endpoint for Fusion Studio API
     */
    public static String DEFAULT_ENDPOINT = "fusiondb";

    /**
     * Environment variable name for setting the API Host
     */
    public static String ENV_VAR_FS_API_HOST = "FS_API_HOST";

    /**
     * Environment variable name for setting the API Port
     */
    public static String ENV_VAR_FS_API_PORT = "FS_API_PORT";

    /**
     * Get the Base URI for the Fusion Studio API.
     *
     * The URI can be overriden by environment variables
     * see {@link #ENV_VAR_FS_API_HOST} and {@link #ENV_VAR_FS_API_PORT}.
     *
     * @return the base URI
     */
    public static String getApiBaseUri() {
        final String host = envVarOrDefault(ENV_VAR_FS_API_HOST, DEFAULT_HOST, envVarValue -> envVarValue);
        final int port = envVarOrDefault(ENV_VAR_FS_API_PORT, DEFAULT_PORT, envVarValue -> {
            try {
                return Integer.parseInt(envVarValue);
            } catch (final NumberFormatException e) {
                // invalid number
                System.err.println("ENV.FS_API_PORT=" + envVarValue + ", is not a valid TCP port number. Using default: " + DEFAULT_PORT);
                e.printStackTrace();
                return DEFAULT_PORT;
            }
        });

        return "http://" + host + ":" + port + "/exist/restxq/" + DEFAULT_ENDPOINT;
    }

    /**
     * Gets a value from an Environment variable or uses the default
     * if there is no such variable.
     *
     * @param envVarName the name of the environment variable.
     * @param defaultValue the default value to use if there is no environment variable
     * @param typeConverter a function for converting the value of the environment
     *     variable (if present) to the desired type
     *
     * @return the value from the environment variable, or the default value
     */
    private static <T> T envVarOrDefault(final String envVarName, final T defaultValue, final Function<String, T> typeConverter) {
        final String envVarValue = System.getenv(envVarName);
        if (envVarValue != null && !envVarValue.isEmpty()) {
            return typeConverter.apply(envVarValue);
        } else {
            return defaultValue;
        }
    }
}
