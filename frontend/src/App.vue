<template>
  <!-- Main dashboard container -->
  <div class="main-bg" style="font-family: 'Inter', 'Segoe UI', Arial, sans-serif; min-height: 100vh; padding: 2rem;">
    <!-- Title and highlight -->
    <h1 class="main-title">📡 MTNA Listowel - <span class="highlight">Live OEE Dashboard</span></h1>
    <!-- Sorting controls for OEE -->
    <div class="sort-row">
      <label for="sortOrder" class="sort-label">Sort by OEE:</label>
      <select id="sortOrder" v-model="sortOrder" class="sort-select">
        <option value="high-to-low">High to Low</option>
        <option value="low-to-high">Low to High</option>
        <option value="a-to-z">A to Z</option>
        <option value="z-to-a">Z to A</option>
      </select>
    </div>
    <!-- WebSocket connection status -->
    <p v-if="!connected" class="status-msg">Connecting to WebSocket...</p>
    <p v-if="connected" class="status-msg connected">✅ Connected</p>
    <!-- OEE Grid View: displays a card for each machine -->
    <div class="oee-grid">
      <div
        v-for="([machineName, machineTags], idx) in sortedMachines"
        :key="machineName"
        class="oee-card-wrapper"
      >
        <!-- MachineDashboard component renders metrics for each machine -->
        <MachineDashboard
          :tags="machineTags"
          :tagPath="machineName"
        />
      </div>
    </div>
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
      tags: {},        // { machine: { metric: value } } - Holds all machine metrics keyed by machine name
      connected: false, // WebSocket connection status
      sortOrder: 'high-to-low', // Sorting order for dashboard
    }
  },
  computed: {
    // Returns a sorted array of [machineName, machineTags] based on sortOrder
    sortedMachines() {
      // Convert tags object to array of [machineName, machineTags]
      const arr = Object.entries(this.tags);
      // Sort by OEE value or machine name
      arr.sort((a, b) => {
        if (this.sortOrder === 'a-to-z') {
          return a[0].localeCompare(b[0]);
        } else if (this.sortOrder === 'z-to-a') {
          return b[0].localeCompare(a[0]);
        } else {
          const oeeA = parseFloat(a[1].oee) || 0;
          const oeeB = parseFloat(b[1].oee) || 0;
          if (this.sortOrder === 'low-to-high') {
            return oeeA - oeeB;
          } else {
            return oeeB - oeeA;
          }
        }
      });
      return arr;
    }
  },
  methods: {
    // Update a specific tag value for a machine
    updateTag(name, value) {
      const [machine, metric] = name.split('/')
      if (!machine || !metric) return
      const parsedValue = isNaN(Number(value)) ? value : Number(value)
      if (!this.tags[machine]) {
        this.tags = { ...this.tags, [machine]: { [metric]: parsedValue } }
      } else {
        this.tags = {
          ...this.tags,
          [machine]: { ...this.tags[machine], [metric]: parsedValue }
        }
      }
    },
    // Establishes a WebSocket connection to the backend for real-time updates
    connectWebSocket() {
      const socket = new WebSocket("ws://localhost:8000/ws")
      socket.onopen = () => {
        console.log("✅ WebSocket connected")
        this.connected = true
      }
      socket.onmessage = (event) => {
        console.log("📨 WebSocket message received:", event.data)
        const [name, value] = event.data.split(" = ")
        if (name && value !== undefined) {
          this.updateTag(name, value)
        }
      }
      socket.onclose = () => {
        console.log("❌ WebSocket disconnected")
        this.connected = false
        setTimeout(() => this.connectWebSocket(), 2000)
      }
    },
    // Fetches the initial set of tags/metrics from the backend REST API
    async fetchInitialTags() {
      try {
        const res = await fetch("http://localhost:8000/api/tags")
        const tagNames = await res.json()
        for (const name of tagNames) {
          const encoded = encodeURIComponent(name)
          const res = await fetch(`http://localhost:8000/api/tags/${encoded}`)
          if (res.ok) {
            const { value } = await res.json()
            this.updateTag(name, value)
          } else {
            console.warn(`Tag ${name} not found in backend`)
          }
        }
      } catch (err) {
        console.error("Failed to fetch initial tags", err)
      }
    }
  },
  async mounted() {
    // On mount, fetch initial tags and connect to WebSocket for live updates
    await this.fetchInitialTags()
    this.connectWebSocket()
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap');

.main-bg {
  min-height: 100vh;
  background: linear-gradient(120deg, #f8fafc 0%, #e0c3fc 100%);
}
.main-title {
  font-size: 2.7rem;
  font-weight: 800;
  letter-spacing: -1px;
  color: #3d246c;
  margin-bottom: 1.2rem;
  text-shadow: 0 2px 12px #a259ec22;
}
.main-title .highlight {
  color: #e84393;
  background: linear-gradient(90deg, #e84393 0%, #0984e3 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
.status-msg {
  font-size: 1.1rem;
  color: #636e72;
  margin-bottom: 1.5rem;
}
.status-msg.connected {
  color: #00b894;
  font-weight: 600;
}
.oee-grid {
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  gap: 2rem 1.5rem;
  margin-bottom: 2rem;
}
.oee-card-wrapper {
  position: relative;
  transition: grid-column 0.3s, box-shadow 0.2s, transform 0.2s;
  cursor: pointer;
  /* Only handle grid/hover/expansion, not card look */
}
.oee-card-wrapper:hover {
  box-shadow: 0 8px 32px #a259ec33;
  transform: translateY(-4px) scale(1.03);
  z-index: 3;
}
.oee-card-wrapper.expanded {
  z-index: 2;
  grid-column: span 2;
  box-shadow: 0 8px 32px #a259ec44;
  transform: scale(1.04);
  /* No border, let card handle its own look */
}
.card-accent {
  width: 8px;
  border-radius: 1.2rem 0 0 1.2rem;
  margin-right: -8px;
  background: #a259ec;
  flex-shrink: 0;
}
.close-btn-inline {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: #d63031;
  color: #fff;
  border: none;
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  cursor: pointer;
  z-index: 10;
  box-shadow: 0 2px 8px #d6303122;
  transition: background 0.2s;
}
.close-btn-inline:hover {
  background: #b71c1c;
}
.sort-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.2rem;
}
.sort-label {
  font-size: 1.1rem;
  color: #636e72;
  font-weight: 500;
}
.sort-select {
  font-size: 1.1rem;
  padding: 0.3rem 1.2rem 0.3rem 0.7rem;
  border-radius: 0.5rem;
  border: 1.5px solid #a259ec55;
  background: #f8fafc;
  color: #3d246c;
  font-weight: 600;
  outline: none;
  transition: border 0.2s;
}
.sort-select:focus {
  border: 1.5px solid #a259ec;
}
</style>
