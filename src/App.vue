<template>
  <div style="font-family: sans-serif; padding: 2rem">
    <h1>📡 Sparkplug Live Tag Viewer</h1>
    <p v-if="!connected">Connecting to WebSocket...</p>
    <p v-if="connected">✅ Connected</p>

    <!-- OEE Dashboard -->
    <div class="dashboard">
      <div class="dashboard-header">
        <div class="machine-label">
          <div class="machine-title">Machine 1</div>
          <div class="machine-online">
            Online: <b :style="{color: tags['Machines/Machine 1/Availability/Machine Online']==='True' ? '#00b894' : '#d63031'}">{{ tags['Machines/Machine 1/Availability/Machine Online'] }}</b>
          </div>
          <div class="oee-label-side">
            <span>OEE</span>
            <span class="oee-value-side">{{ typeof oee === 'string' ? oee : oee + '%' }}</span>
          </div>
        </div>
        <div class="gauges-row">
          <div class="gauge-card">
            <apexchart type="radialBar" height="220" :options="gaugeOptions('Availability', availability, '#a259ec')" :series="[availability]"></apexchart>
            <div class="gauge-attrs">
              <div>Run Time: <b>{{ tags['Machines/Machine 1/Availability/Run Time'] || '-' }}</b></div>
              <div>Production Time: <b>{{ tags['Machines/Machine 1/Availability/Production Time'] || '-' }}</b></div>
              <div>Down Time: <b>{{ tags['Machines/Machine 1/Availability/Down Time'] || '-' }}</b></div>
              <div>Start Time: <b>{{ formatTimestamp(tags['Machines/Machine 1/Availability/Start Time']) }}</b></div>
            </div>
          </div>
          <div class="gauge-card">
            <apexchart type="radialBar" height="220" :options="gaugeOptions('Performance', performance, '#0984e3')" :series="[performance]"></apexchart>
            <div class="gauge-attrs">
              <div>Ideal Cycle: <b>{{ tags['Machines/Machine 1/Performance/Ideal Cycle Time'] || '-' }}</b></div>
              <div>Avg Cycle: <b>{{ tags['Machines/Machine 1/Performance/Avg Cycle Time'] || '-' }}</b></div>
            </div>
          </div>
          <div class="gauge-card">
            <apexchart type="radialBar" height="220" :options="gaugeOptions('Quality', quality, '#fdcb6e')" :series="[quality]"></apexchart>
            <div class="gauge-attrs">
              <div>Good Count: <b>{{ tags['Machines/Machine 1/Quality/Good Count'] || '-' }}</b></div>
              <div>Reject Count: <b>{{ tags['Machines/Machine 1/Quality/Reject Count'] || '-' }}</b></div>
              <div>Total Count: <b>{{ tags['Machines/Machine 1/Quality/Total Count'] || '-' }}</b></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <h2>Live Tags</h2>
    <table border="1" cellpadding="6">
      <tr><th>Tag Name</th><th>Value</th></tr>
      <tr v-for="(value, name) in tags" :key="name">
        <td>{{ name }}</td>
        <td>{{ value }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
import ApexCharts from 'apexcharts'
import VueApexCharts from 'vue3-apexcharts'

export default {
  components: {
    apexchart: VueApexCharts
  },
  data() {
    return {
      tags: {},        // tagName: value
      connected: false
    }
  },
  computed: {
    availability() {
      const v = parseFloat(this.tags['Machines/Machine 1/Availability/Availabilty'])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    performance() {
      const v = parseFloat(this.tags['Machines/Machine 1/Performance/Performance'])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    quality() {
      const v = parseFloat(this.tags['Machines/Machine 1/Quality/Quality'])
      return isNaN(v) ? 0 : Math.round(v * 10000) / 100
    },
    oee() {
      const v = parseFloat(this.tags['Machines/Machine 1/OEE'])
      return isNaN(v) ? '-' : (Math.round(v * 10000) / 100) + '%'
    }
  },
  methods: {
    connectWebSocket() {
      const socket = new WebSocket("ws://localhost:8000/ws")
      socket.onopen = () => {
        console.log("✅ WebSocket connected")
        this.connected = true
      }

      socket.onmessage = (event) => {
        console.log("📨 WebSocket message received:", event.data)
        // Message format: "TagName = Value"
        const [name, value] = event.data.split(" = ")
        if (name && value !== undefined) {
          if (Object.prototype.hasOwnProperty.call(this.tags, name)) {
            this.tags[name] = value
          } else {
            this.tags = { ...this.tags, [name]: value }
          }
        }
      }

      socket.onclose = () => {
        console.log("❌ WebSocket disconnected")
        this.connected = false
        setTimeout(() => this.connectWebSocket(), 2000) // Retry
      }
    },
    async fetchInitialTags() {
      try {
        const res = await fetch("http://localhost:8000/api/tags")
        const tagNames = await res.json()

        for (const name of tagNames) {
          const encoded = encodeURIComponent(name)
          const res = await fetch(`http://localhost:8000/api/tags/${encoded}`)
          if (res.ok) {
            const { value } = await res.json()
            this.tags[name] = value
          } else {
            console.warn(`Tag ${name} not found in backend`)
          }
        }
      } catch (err) {
        console.error("Failed to fetch initial tags", err)
      }
    },
    formatTimestamp(ts) {
      if (!ts) return '-'
      const d = new Date(Number(ts))
      if (isNaN(d.getTime())) return '-'
      return d.toLocaleString()
    },
    gaugeOptions(label, value, color) {
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
                formatter: val => val + '%'
              }
            }
          }
        },
        fill: { colors: [color] },
        labels: [label],
        stroke: { lineCap: 'round' }
      }
    }
  },
  async mounted() {
    await this.fetchInitialTags()
    this.connectWebSocket()
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
}
.oee-value-side {
  font-size: 2.1rem;
  color: #00b894;
  font-weight: bold;
}
.gauges-row {
  display: flex;
  justify-content: space-around;
  gap: 2rem;
  margin-bottom: 1.5rem;
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
</style>
