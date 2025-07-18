<template>
  <div style="font-family: sans-serif; padding: 2rem">
    <h1>📡 Sparkplug Live Tag Viewer</h1>
    <p v-if="!connected">Connecting to WebSocket...</p>
    <p v-if="connected">✅ Connected</p>

    <!-- OEE Dashboard -->
    <MachineDashboard 
      :tagPath="'Machines/Machine 1'" 
      :tags="tags" 
    />
    
    <!-- Example: You can now easily add more machines -->
    <!-- 
    <MachineDashboard 
      :tagPath="'Machines/Machine 2'" 
      :tags="tags" 
    />
    <MachineDashboard 
      :tagPath="'Machines/Production Line A'" 
      :tags="tags" 
    />
    -->

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
import VueApexCharts from 'vue3-apexcharts'
import MachineDashboard from './components/MachineDashboard.vue'

export default {
  components: {
    apexchart: VueApexCharts,
    MachineDashboard
  },
  data() {
    return {
      tags: {},        // tagName: value
      connected: false
    }
  },
  computed: {
    // Computed properties moved to MachineDashboard component
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
    }
  },
  async mounted() {
    await this.fetchInitialTags()
    this.connectWebSocket()
  }
}
</script>

<style scoped>
/* Styles moved to MachineDashboard component */
</style>
