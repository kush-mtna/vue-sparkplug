<template>
  <div class="dashboard">
    <div class="dashboard-header">
      <div class="gauges-row four-col-row">
        <div class="oee-card oee-card-col">
          <div class="machine-title">{{ machineTitle }}</div>
          <div class="machine-online">
            Online: <b :style="{color: tags[`${tagPath}/Availability/Machine Online`]==='True' ? '#00b894' : '#d63031'}">{{ tags[`${tagPath}/Availability/Machine Online`] }}</b>
          </div>
          <div class="oee-label-side">
            <span>OEE</span>
            <span class="oee-value-side">{{ oee }}</span>
          </div>
          <div v-if="oeeRaw > 100" class="gauge-warning" style="margin-top:0.2rem;"><span class="gauge-warning-note">Something is wrong, OEE should not exceed 100%</span></div>
        </div>
        <div class="gauge-card">
          <apexchart type="radialBar" height="220" :options="gaugeOptions('Availability', availability, '#a259ec', availabilityRaw)" :series="[availability]" />
          <div v-if="availabilityRaw > 100" class="gauge-warning"><span class="gauge-warning-note">Something is wrong, availability should not exceed 100%</span></div>
                      <div class="gauge-attrs">
              <div>Run Time: <b>{{ formatTime(tags[`${tagPath}/Availability/Run Time`]) }}</b></div>
              <div>Production Time: <b>{{ formatTime(tags[`${tagPath}/Availability/Production Time`]) }}</b></div>
              <div>Down Time: <b>{{ formatTime(tags[`${tagPath}/Availability/Down Time`]) }}</b></div>
            </div>
        </div>
        <div class="gauge-card">
          <apexchart type="radialBar" height="220" :options="gaugeOptions('Performance', performance, '#0984e3', performanceRaw)" :series="[performance]" />
          <div v-if="performanceRaw > 100" class="gauge-warning"><span class="gauge-warning-note">Something is wrong, performance should not exceed 100%</span></div>
                      <div class="gauge-attrs">
              <div>Ideal Cycle: <b>{{ formatTime(tags[`${tagPath}/Performance/Ideal Cycle Time`]) }}</b></div>
              <div>Avg Cycle: <b>{{ formatAvgCycle(tags[`${tagPath}/Performance/Avg Cycle Time`]) }}</b></div>
            </div>
        </div>
        <div class="gauge-card">
          <apexchart type="radialBar" height="220" :options="gaugeOptions('Quality', quality, '#fdcb6e', qualityRaw)" :series="[quality]" />
          <div v-if="qualityRaw > 100" class="gauge-warning"><span class="gauge-warning-note">Something is wrong, quality should not exceed 100%</span></div>
          <div class="gauge-attrs">
            <div>Good Count: <b>{{ tags[`${tagPath}/Quality/Good Count`] || '-' }}</b></div>
            <div>Reject Count: <b>{{ tags[`${tagPath}/Quality/Reject Count`] || '-' }}</b></div>
            <div>Total Count: <b>{{ tags[`${tagPath}/Quality/Total Count`] || '-' }}</b></div>
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
    tagPath: {
      type: String,
      required: true,
      default: 'Machines/Machine 1'
    },
    tags: {
      type: Object,
      required: true,
      default: () => ({})
    }
  },
  computed: {
    machineTitle() {
      // Extract the machine title from the tagPath (everything after the last '/')
      const parts = this.tagPath.split('/')
      return parts[parts.length - 1] || 'Machine'
    },
    availability() {
      const v = parseFloat(this.tags[`${this.tagPath}/Availability/Availabilty`])
      const percent = isNaN(v) ? 0 : Math.round(v * 10000) / 100
      return percent > 100 ? 100 : percent
    },
    performance() {
      const v = parseFloat(this.tags[`${this.tagPath}/Performance/Performance`])
      const percent = isNaN(v) ? 0 : Math.round(v * 10000) / 100
      return percent > 100 ? 100 : percent
    },
    quality() {
      const v = parseFloat(this.tags[`${this.tagPath}/Quality/Quality`])
      const percent = isNaN(v) ? 0 : Math.round(v * 10000) / 100
      return percent > 100 ? 100 : percent
    },
    availabilityRaw() {
      const v = parseFloat(this.tags[`${this.tagPath}/Availability/Availabilty`])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    performanceRaw() {
      const v = parseFloat(this.tags[`${this.tagPath}/Performance/Performance`])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    qualityRaw() {
      const v = parseFloat(this.tags[`${this.tagPath}/Quality/Quality`])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    oee() {
      const v = parseFloat(this.tags[`${this.tagPath}/OEE`])
      const percent = isNaN(v) ? 0 : Math.round(v * 10000) / 100
      return percent > 100 ? '100+%' : percent + '%'
    },
    oeeRaw() {
      const v = parseFloat(this.tags[`${this.tagPath}/OEE`])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    }
  },
  methods: {
    formatTime(value) {
      if (!value || value === '-') return '-'
      const num = parseFloat(value)
      return isNaN(num) ? '-' : num.toFixed(2) + 's'
    },
    formatAvgCycle(value) {
      if (!value || value === '-') return '-'
      const num = parseFloat(value)
      return isNaN(num) ? '-' : num.toFixed(2) + 's'
    },
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
                offsetY: 30,
                show: true,
                color: '#888',
                fontSize: '18px'
              },
              value: {
                offsetY: -10,
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
  padding: 1.2rem 1.2rem 0.5rem 1.2rem;
  width: 320px;
  display: flex;
  flex-direction: column;
  align-items: center;
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
</style> 