<template>
  <b-container fluid="xl">
    <page-title :description="description" />
    <b-row>
      <b-col md="8" xl="6">
        <b-form-group>
          <b-form-checkbox v-model="enabled" switch data-test-id="demoMode-switch">
            {{ enabled ? 'Demo mode is enabled' : 'Demo mode is disabled' }}
          </b-form-checkbox>
        </b-form-group>
        <b-alert :model-value="true" variant="info">
          Changing this setting reloads the WebUI so demo data is applied from
          the start.
        </b-alert>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
import PageTitle from '@/components/Global/PageTitle';
import { isDemoMode, setDemoMode } from '@/env/demo/config';

export default {
  name: 'DemoMode',
  components: { PageTitle },
  data() {
    return {
      enabled: isDemoMode,
      description:
        'Demo mode makes this WebUI display fixed, representative data from a ' +
        'built-in mock instead of talking to the BMC. Use it to showcase the ' +
        'dashboard when no host, FRU EEPROM or sensors are available.',
    };
  },
  watch: {
    enabled(value) {
      setDemoMode(value);
      // Reload so the mock adapter and demo session are set up from boot.
      window.location.reload();
    },
  },
};
</script>
