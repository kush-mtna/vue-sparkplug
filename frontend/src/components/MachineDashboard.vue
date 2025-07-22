<template>
  <!-- Card for displaying OEE and metrics for a single machine -->
  <div>
    <div class="oee-card" :class="{ 'card-stopped': tags.status === 'stopped', 'card-offline': tags.status === 'offline' }">
      <!-- Status label (running, stopped, offline, etc.) -->
      <span v-if="tags.status" :class="['status-label', { 'status-green': tags.status === 'fullauto' || tags.status === 'running' || tags.status === 'starting', 'status-red': tags.status === 'offline', 'status-orange': tags.status === 'down' }]">{{ tags.status }}</span>
      <!-- Machine name -->
      <div class="machine-title title">{{ tagPath }}</div>
      <!-- OEE value and label -->
      <div class="oee-label-side oee-label">
        <span>OEE</span>
        <span
          class="oee-value-side oee-value"
          :class="oeeColorClass"
        >{{ oee }}</span>
      </div>
      <!-- Condensed metrics: Availability, Performance, Quality -->
      <div class="metrics-condensed">
        <div class="metric-row metric-row">
          <span class="metric-label metric-label">Availability</span>
          <span class="metric-value metric-value">{{ availability.toFixed(2) }}%</span>
        </div>
        <div class="bar-container bar-container">
          <div class="bar-bg bar-bg">
            <div class="bar-fill availability-bar bar-fill" :style="{ width: availability + '%' }"></div>
          </div>
        </div>
        <div class="metric-row metric-row">
          <span class="metric-label metric-label">Performance</span>
          <span class="metric-value metric-value">{{ performance.toFixed(2) }}%</span>
        </div>
        <div class="bar-container bar-container">
          <div class="bar-bg bar-bg">
            <div class="bar-fill performance-bar bar-fill" :style="{ width: performance + '%' }"></div>
          </div>
        </div>
        <div class="metric-row metric-row">
          <span class="metric-label metric-label">Quality</span>
          <span class="metric-value metric-value">{{ quality.toFixed(2) }}%</span>
        </div>
        <div class="bar-container bar-container">
          <div class="bar-bg bar-bg">
            <div class="bar-fill quality-bar bar-fill" :style="{ width: quality + '%' }"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import VueApexCharts from 'vue3-apexcharts'

export default {
  name: 'MachineDashboard',
  components: {
    apexchart: VueApexCharts
  },
  props: {
    // Object containing all tag values for this machine
    tags: {
      type: Object,
      required: true,
      default: () => ({})
    },
    // The machine name or path
    tagPath: {
      type: String,
      required: true
    },
  },
  computed: {
    // Returns the availability percentage (0-100)
    availability() {
      const v = parseFloat(this.tags['oeeAvailability'])
      const percent = isNaN(v) ? 0 : v
      const clamped = percent > 100 ? 100 : percent
      return Number(clamped.toFixed(2))
    },
    // Returns the performance percentage (0-100)
    performance() {
      const v = parseFloat(this.tags['oeePerformance'])
      const percent = isNaN(v) ? 0 : v
      const clamped = percent > 100 ? 100 : percent
      return Number(clamped.toFixed(2))
    },
    // Returns the quality percentage (0-100)
    quality() {
      const v = parseFloat(this.tags['oeeQuality'])
      const percent = isNaN(v) ? 0 : v
      const clamped = percent > 100 ? 100 : percent
      return Number(clamped.toFixed(2))
    },
    // Returns the OEE value as a string with percent sign
    oee() {
      const v = parseFloat(this.tags['oee'])
      const percent = isNaN(v) ? 0 : v
      const clamped = percent > 100 ? 100 : percent
      return clamped.toFixed(2) + '%'
    },
    // Returns a class for OEE color based on thresholds
    oeeColorClass() {
      const v = parseFloat(this.tags['oee'])
      // Read thresholds from Vite environment variables, fallback to defaults if not set
      const green = parseFloat(import.meta.env.VITE_OEE_GREEN_THRESHOLD) || 90
      const orange = parseFloat(import.meta.env.VITE_OEE_ORANGE_THRESHOLD) || 80
      if (v > green) return 'oee-green'
      if (v >= orange) return 'oee-orange'
      return 'oee-red'
    }
  },
  methods: {
    // Returns ApexCharts options for a radial gauge (not used in main dashboard)
    gaugeOptions(label, value, color, rawValue) {
      return {
        chart: {
          type: 'radialBar',
          sparkline: { enabled: true }
        },
        plotOptions: {
          radialBar: {
            startAngle: -90,
            endAngle: 90,
            track: { background: '#eee', strokeWidth: '97%' },
            hollow: { size: '60%' },
            dataLabels: {
              name: {
                offsetY: 20,
                show: true,
                color: '#888',
                fontSize: '18px'
              },
              value: {
                offsetY: -30,
                fontSize: '28px',
                color: color,
                formatter: (function(rv) { return val => (rv > 100 ? '100+%' : val + '%') })(rawValue)
              }
            }
          }
        },
        fill: { colors: [color] },
        labels: [label],
        stroke: { lineCap: 'round' }
      }
    }
  }
}
</script>

<style scoped>
.dashboard {
  margin: 2rem 0 2.5rem 0;
  background: #f8f9fa;
  border-radius: 1.5rem;
  box-shadow: 0 2px 16px #0001;
  padding: 2rem 1.5rem 1.5rem 1.5rem;
}
.dashboard-header {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  gap: 2.5rem;
  justify-content: center;
  background-color: cadetblue;
  padding: 1.5rem;
  border-radius: 1.5rem;
}
.machine-label {
  min-width: 170px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  margin-right: 1.5rem;
  margin-top: 1.5rem;
}
.machine-title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #636e72;
  margin-bottom: 1.2rem;
}
.machine-online {
  font-size: 1.1rem;
  margin-bottom: 0.7rem;
}
.oee-label-side {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.1rem;
  color: #636e72;
  margin-bottom: 0.5rem;
  width: auto;
}
.oee-value-side {
  font-size: 2.1rem;
  color: #00b894;
  font-weight: bold;
}
.four-col-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  gap: 1.5rem;
}
.oee-card-col {
  min-width: 220px;
  max-width: 260px;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fff;
  border-radius: 1rem;
  box-shadow: 0 1px 8px #0001;
  padding: 1.2rem 1.2rem 0.5rem 1.2rem;
}
.oee-attrs {
  margin-top: 0.7rem;
  font-size: 1rem;
  color: #444;
  width: 100%;
}
.oee-attrs div {
  margin-bottom: 0.2rem;
}
.gauge-card {
  background: #fff;
  border-radius: 1rem;
  box-shadow: 0 1px 8px #0001;
  padding: 1.2rem;
  width: 320px;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-bottom: 2.5rem;
}
.gauge-attrs {
  margin-top: 0.5rem;
  font-size: 1rem;
  color: #444;
  width: 100%;
}
.gauge-attrs div {
  margin-bottom: 0.2rem;
}
.oee-row {
  display: flex;
  justify-content: center;
  margin-top: 0.5rem;
}
.oee-card {
  background: #fff;
  border-radius: 1rem;
  box-shadow: 0 1px 8px #0001;
  padding: 1.5rem 3rem;
  text-align: center;
  min-width: 200px;
  width: 200px;
  /* Ensures the card width stays fixed as before */
}
.oee-label {
  font-size: 1.2rem;
  color: #636e72;
  margin-bottom: 0.2rem;
}
.oee-value {
  font-size: 2.5rem;
  color: #00b894;
  font-weight: bold;
}
.gauge-warning {
  color: #d63031;
  font-size: 1.1rem;
  font-weight: bold;
  text-align: center;
  margin-top: 0.5rem;
}
.gauge-warning-note {
  font-size: 0.95rem;
  color: #d63031;
  font-weight: normal;
}
.status-label {
  position: absolute;
  top: 0px;
  left: 0px;
  margin: 0.5rem;
  font-size: 0.62rem;
  background: #eee;
  color: #636e72;
  padding: 1px 7px;
  border-radius: 8px;
  font-weight: 500;
  letter-spacing: 0.5px;
  z-index: 2;
  pointer-events: none;
  box-shadow: 0 1px 4px #0001;
}
.oee-card {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fff;
  border-radius: 1rem;
  box-shadow: 0 1px 8px #0001;
  padding: 1.5rem;
  min-width: 180px;
  min-height: 120px;
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.expanded-metrics {
  margin-top: 1.5rem;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
}
.metric-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  width: 100%;
  font-size: 1.15rem;
  padding: 0.2rem 0.5rem;
}
.metric-label {
  color: #636e72;
  font-weight: 500;
}
.metric-value {
  color: #000;
  font-weight: bold;
}
.bar-container {
  width: 100%;
  margin: 0.2rem 0 0.7rem 0;
  display: flex;
  align-items: center;
}
.bar-bg {
  width: 100%;
  height: 18px;
  background: #eee;
  border-radius: 9px;
  overflow: hidden;
  position: relative;
}
.bar-fill {
  height: 100%;
  border-radius: 9px;
  transition: width 0.5s cubic-bezier(0.4,0,0.2,1);
}
.availability-bar {
  background: #a259ec;
}
.performance-bar {
  background: #e84393;
}
.quality-bar {
  background: #0984e3;
}
.title {
  font-size: 0.95rem;
  margin-bottom: 0.2rem;
  text-align: center;
  word-break: break-all;
}
.oee-label {
  font-size: 0.7rem;
  gap: 0.2rem;
  margin-bottom: 0.1rem;
  margin-top: 0.5rem;
}
.oee-value {
  font-size: 1.1rem;
}
.metrics-condensed {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.05rem;
  margin-top: 0.5rem; /* Add margin to separate OEE from metrics */
}
.metric-row {
  font-size: 0.7rem;
  padding: 0.05rem 0.1rem;
  justify-content: space-between;
}
.metric-label {
  font-weight: 500;
  color: #636e72;
}
.metric-value {
  color: #636e72;
  font-weight: bold;
}
.bar-container {
  margin: 0.01rem 0 0.5rem 0;
  height: 8px;
}
.bar-bg {
  height: 8px;
  border-radius: 4px;
}
.bar-fill {
  height: 8px;
  border-radius: 4px;
}
.oee-green {
  color: #00b894 !important;
}
.oee-orange {
  color: #fdcb6e !important;
}
.oee-red {
  color: #d63031 !important;
}
.card-stopped {
  filter: grayscale(1) brightness(0.82);
  opacity: 0.45;
  pointer-events: none;
}
.status-green {
  background: #d4fbe2;
  color: #00b894;
  border: 1px solid #00b894;
}
.status-red {
  background: #fff0f0;
  color: #d63031;
  border: 1px solid #d63031;
}
.status-orange {
  background: #fff6e0;
  color: #fdcb6e;
  border: 1px solid #fdcb6e;
}
@keyframes flash-warning {
  0%, 100% { box-shadow: 0 0 0 0 #ffe06600, 0 0 0 0 #ffe06600; }
  50% { box-shadow: 0 0 32px 12px #ffe066cc, 0 0 0 0 #ffe06600; }
}
.card-offline {
  animation: flash-warning 1.7s infinite alternate;
}
</style> 