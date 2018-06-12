
/*
 * Copyright (C) 2015 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package io.k8s.cassandra;

import io.kubernetes.client.ApiClient;
import io.kubernetes.client.ApiException;
import io.kubernetes.client.Configuration;
import io.kubernetes.client.apis.CoreV1Api;
import io.kubernetes.client.models.V1Endpoints;
import io.kubernetes.client.models.V1EndpointAddress;
import io.kubernetes.client.models.V1EndpointSubset;
import io.kubernetes.client.util.Config;

import java.io.IOException;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.apache.cassandra.locator.SeedProvider;
import org.codehaus.jackson.annotate.JsonIgnoreProperties;
import org.codehaus.jackson.map.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.sun.jna.Native;

/**
 * Self discovery {@link SeedProvider} that creates a list of Cassandra Seeds by
 * communicating with the Kubernetes API.
 * <p>
 * Various System Variable can be used to configure this provider:
 * <ul>
 * <li>CASSANDRA_SERVICE defaults to cassandra</li>
 * <li>POD_NAMESPACE defaults to 'default'</li>
 * <li>CASSANDRA_SERVICE_NUM_SEEDS defaults to 8 seeds</li>
 * </ul>
 */
public class KubernetesSeedProvider implements SeedProvider {

	private static final Logger logger = LoggerFactory.getLogger(KubernetesSeedProvider.class);


	/**
	 * Create new seed provider
	 *
	 * @param params
	 */
	public KubernetesSeedProvider(Map<String, String> params) {
	}

	/**
	 * Call Kubernetes API to collect a list of seed providers
	 *
	 * @return list of seed providers
	 */
	public List<InetAddress> getSeeds() {
        List<InetAddress> seeds = new ArrayList<InetAddress>();

		String service = getEnvOrDefault("CASSANDRA_SERVICE", "cassandra");
		String namespace = getEnvOrDefault("POD_NAMESPACE", "default");

		String initialSeeds = getEnvOrDefault("CASSANDRA_SEEDS", "");
		if (initialSeeds.equals("")) {
			initialSeeds = getEnvOrDefault("POD_IP", "");
		}

		try {
            ApiClient client = Config.defaultClient();
            Configuration.setDefaultApiClient(client);

            CoreV1Api coreApi = new CoreV1Api(client);
            String pretty = "false"; // String | If 'true', then the output is pretty printed.
            Boolean exact = true; // Boolean | Should the export be exact.  Exact export maintains cluster-specific fields like 'Namespace'.
            Boolean export = true; // Boolean | Should this value be exported.  Export strips fields that a user can not specify.
            V1Endpoints endpoints =
                coreApi.readNamespacedEndpoints(service, namespace, pretty, exact, export);
            if (endpoints != null && endpoints.getSubsets() != null) {
                for (V1EndpointSubset subset : endpoints.getSubsets()) {
                    if (subset != null && subset.getAddresses() != null) {
                        for (V1EndpointAddress address : subset.getAddresses()) {
                            if (address != null && address.getIp() != null) {
                                seeds.add(InetAddress.getByName(address.getIp()));
                            }
                        }
                    }
                }
            }
            if (seeds.isEmpty()) {
                // returning default seeds if there is no endpoints
                String[] defSeeds = initialSeeds.split(",");
                for (String defSeed : defSeeds) {
                    seeds.add(InetAddress.getByName(defSeed));
                }
            }
			logger.info("Cassandra seeds: " + seeds.toString());
			return Collections.unmodifiableList(seeds);
        } catch (IOException|ApiException e) {
			// This should not happen
			logger.error("Unexpected error building cassandra seeds: " + e.getMessage());
			return Collections.emptyList();
		}
	}

	private static String getEnvOrDefault(String var, String def) {
		String val = System.getenv(var);
		if (val == null) {
			val = def;
		}
		return val;
	}
}
