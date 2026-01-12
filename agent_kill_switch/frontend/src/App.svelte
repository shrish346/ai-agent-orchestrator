<script>
  import { onMount } from "svelte";
  import { channel } from "./lib/socket";

  let agents = {};
  let selectedAgentId = null;
  let currentTab = "dashboard";
  let terminatedCount = 0;

  $: agentList = Object.values(agents).sort((a, b) => a.id.localeCompare(b.id));
  $: selectedAgent = agents[selectedAgentId];
  $: healthyCount = agentList.filter((a) => a.status === "healthy").length;
  $: warningCount = agentList.filter((a) => a.status === "warning").length;
  $: maliciousCount = agentList.filter((a) => a.status === "malicious").length;
  $: totalAgents = agentList.length;

  onMount(() => {
    channel.on("agent_update", (payload) => {
      agents[payload.id] = payload;
      agents = agents;
    });

    channel.on("agent_terminated", (payload) => {
      delete agents[payload.id];
      agents = agents;
      terminatedCount++;
      if (selectedAgentId === payload.id) {
        selectedAgentId = null;
      }
    });
  });

  async function killAgent(id) {
    try {
      const response = await fetch(
        `http://localhost:4000/api/agents/${id}/kill`,
        {
          method: "POST",
        }
      );
      if (!response.ok) {
        const error = await response.json();
        console.error("Failed to kill agent:", error);
      }
    } catch (err) {
      console.error("Network error when killing agent:", err);
    }
  }

  async function spawnAgent() {
    try {
      const response = await fetch("http://localhost:4000/api/agents", {
        method: "POST",
      });
      if (!response.ok) {
        const error = await response.json();
        console.error("Failed to spawn agent:", error);
      }
    } catch (err) {
      console.error("Network error when spawning agent:", err);
    }
  }

  function formatTime(isoString) {
    return new Date(isoString).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  }

  function getBadgeClass(status) {
    if (status === "malicious") return "badge-red";
    if (status === "warning") return "badge-yellow";
    return "badge-green";
  }

  function getDotClass(status) {
    if (status === "malicious") return "dot-red";
    if (status === "warning") return "dot-yellow";
    return "dot-green";
  }
</script>

<div class="sidebar">
  <div
    style="font-size: 0.7rem; font-weight: 700; color: #fff; margin-bottom: 2rem; display: flex; flex-direction: column; align-items: center; gap: 0.5rem; text-align: center;"
  >
    <div
      style="width: 24px; height: 24px; background: var(--accent-blue); border-radius: 4px;"
    ></div>
    AGENT TRACKER
  </div>

  <div style="display: flex; flex-direction: column; gap: 0.5rem;">
    <button
      class="nav-item"
      class:active={currentTab === "dashboard"}
      on:click={() => (currentTab = "dashboard")}
    >
      Dashboard
    </button>
    <button
      class="nav-item"
      class:active={currentTab === "visualization"}
      on:click={() => (currentTab = "visualization")}
    >
      Visualization
    </button>
  </div>
</div>

<div class="main-content">
  {#if currentTab === "dashboard"}
    <header class="header">
      <div>
        <h1
          style="margin: 0; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.02rem;"
        >
          Agent Monitoring
        </h1>
        <div class="text-muted">
          Real-time fail-safe orchestration dashboard
        </div>
      </div>
      <button class="btn btn-primary" on:click={spawnAgent}
        >+ Spawn Agent</button
      >
    </header>

    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-title">Total Active Agents</div>
        <div class="metric-value">{totalAgents}</div>
      </div>
      <div class="metric-card">
        <div class="metric-title">Anomalies Detected</div>
        <div class="metric-value" style="color: var(--status-red);">
          {maliciousCount}
        </div>
      </div>
      <div class="metric-card">
        <div class="metric-title">System Health</div>
        <div class="metric-value" style="color: var(--status-green);">
          98.4%
        </div>
      </div>
      <div class="metric-card">
        <div class="metric-title">Session Uptime</div>
        <div class="metric-value">04:12:45h</div>
      </div>
    </div>

    <div
      style="display: grid; grid-template-columns: 1fr 450px; gap: 1.5rem; align-items: start;"
    >
      <section class="card" style="padding: 0;">
        <div
          style="padding: 1.25rem; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;"
        >
          <h2 style="margin: 0; font-size: 1rem;">Active Sub-Processes</h2>
          <div class="text-muted">Sorted by ID</div>
        </div>
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Agent ID</th>
                <th>Status</th>
                <th>Last Heartbeat</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {#each agentList as agent (agent.id)}
                <tr
                  class:selected={selectedAgentId === agent.id}
                  on:click={() => (selectedAgentId = agent.id)}
                  on:keydown={(e) =>
                    (e.key === "Enter" || e.key === " ") &&
                    (selectedAgentId = agent.id)}
                  style="cursor: pointer;"
                  role="button"
                  tabindex="0"
                >
                  <td
                    style="font-family: 'JetBrains Mono', monospace; font-size: 0.8rem;"
                    >{agent.id}</td
                  >
                  <td>
                    <span class="badge {getBadgeClass(agent.status)}"
                      >{agent.status}</span
                    >
                  </td>
                  <td class="text-muted">{formatTime(agent.last_heartbeat)}</td>
                  <td>
                    <button
                      class="btn btn-danger"
                      on:click|stopPropagation={() => killAgent(agent.id)}
                      >Kill</button
                    >
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </section>

      <aside class="card" style="padding: 0;">
        <div
          style="padding: 1.25rem; border-bottom: 1px solid var(--border-color);"
        >
          <h2 style="margin: 0; font-size: 1rem;">Telemetry Feed</h2>
        </div>
        <div style="padding: 1.25rem;">
          {#if selectedAgent}
            <div class="log-view">
              {#each selectedAgent.log as entry}
                <div class="log-item">
                  <div
                    class="log-dot {getDotClass(entry.status)}"
                    style="visibility: {entry.status === 'healthy'
                      ? 'hidden'
                      : 'visible'}"
                  ></div>
                  <div class="log-content">
                    <div style="margin-bottom: 0.25rem;">
                      {entry.message}
                    </div>
                    <div class="log-time">
                      {formatTime(entry.timestamp)}
                    </div>
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <div
              style="height: 300px; display: flex; flex-direction: column; align-items: center; justify-content: center; color: var(--text-muted); text-align: center;"
            >
              <div style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.2;">
                📡
              </div>
              Select an agent process to<br />view real-time telemetry stream
            </div>
          {/if}
        </div>
      </aside>
    </div>
  {:else}
    {@const total =
      healthyCount + warningCount + maliciousCount + terminatedCount || 1}
    {@const healthyPct = (healthyCount / total) * 100}
    {@const warningPct = (warningCount / total) * 100}
    {@const maliciousPct = (maliciousCount / total) * 100}
    {@const terminatedPct = (terminatedCount / total) * 100}

    <header class="header">
      <div>
        <h1
          style="margin: 0; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.02rem;"
        >
          System Visualization
        </h1>
        <div class="text-muted">Real-time status distribution analysis</div>
      </div>
    </header>

    <div
      class="card"
      style="display: flex; flex-direction: column; align-items: center; padding: 3rem;"
    >
      <h2 style="margin-bottom: 0.5rem;">
        AI Agent Status Distribution Shows System Health
      </h2>
      <div class="text-muted" style="margin-bottom: 3rem;">
        {Math.round((healthyCount / total) * 100)}% of agents operating normally
        during monitoring period
      </div>

      <div style="display: flex; align-items: center; gap: 4rem;">
        <div style="position: relative; width: 400px; height: 400px;">
          <svg
            viewBox="0 0 100 100"
            style="transform: rotate(-90deg); border-radius: 50%;"
          >
            <!-- Healthy -->
            <circle
              r="25"
              cx="50"
              cy="50"
              fill="transparent"
              stroke="var(--status-green)"
              stroke-width="50"
              stroke-dasharray="{healthyPct} 100"
              pathLength="100"
            />

            <!-- Warning -->
            <circle
              r="25"
              cx="50"
              cy="50"
              fill="transparent"
              stroke="var(--status-yellow)"
              stroke-width="50"
              stroke-dasharray="{warningPct} 100"
              stroke-dashoffset="-{healthyPct}"
              pathLength="100"
            />

            <!-- Malicious -->
            <circle
              r="25"
              cx="50"
              cy="50"
              fill="transparent"
              stroke="var(--status-red)"
              stroke-width="50"
              stroke-dasharray="{maliciousPct} 100"
              stroke-dashoffset="-{healthyPct + warningPct}"
              pathLength="100"
            />

            <!-- Terminated -->
            <circle
              r="25"
              cx="50"
              cy="50"
              fill="transparent"
              stroke="#5a7b8a"
              stroke-width="50"
              stroke-dasharray="{terminatedPct} 100"
              stroke-dashoffset="-{healthyPct + warningPct + maliciousPct}"
              pathLength="100"
            />
          </svg>

          <!-- Labels -->
          <div
            style="position: absolute; top: 65%; left: 65%; color: #fff; text-align: center;"
          >
            <div style="font-size: 0.9rem;">Healthy</div>
            <div style="font-size: 1.2rem; font-weight: bold;">
              {healthyCount}
            </div>
          </div>
          <div
            style="position: absolute; top: 25%; left: 45%; color: #fff; text-align: center;"
          >
            <div style="font-size: 0.9rem;">Warning</div>
            <div style="font-size: 1.2rem; font-weight: bold;">
              {warningCount}
            </div>
          </div>
          <div
            style="position: absolute; top: 40%; left: 25%; color: #fff; text-align: center;"
          >
            <div style="font-size: 0.9rem;">Malicious</div>
            <div style="font-size: 1.2rem; font-weight: bold;">
              {maliciousCount}
            </div>
          </div>
          <div
            style="position: absolute; top: 60%; left: 20%; color: #fff; text-align: center;"
          >
            <div style="font-size: 0.8rem;">Terminated</div>
            <div style="font-size: 1.1rem; font-weight: bold;">
              {terminatedCount}
            </div>
          </div>
        </div>

        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <div style="display: flex; align-items: center; gap: 0.75rem;">
            <div
              style="width: 12px; height: 12px; background: var(--status-green);"
            ></div>
            <div class="text-muted">Healthy</div>
          </div>
          <div style="display: flex; align-items: center; gap: 0.75rem;">
            <div
              style="width: 12px; height: 12px; background: var(--status-yellow);"
            ></div>
            <div class="text-muted">Warning</div>
          </div>
          <div style="display: flex; align-items: center; gap: 0.75rem;">
            <div
              style="width: 12px; height: 12px; background: var(--status-red);"
            ></div>
            <div class="text-muted">Malicious</div>
          </div>
          <div style="display: flex; align-items: center; gap: 0.75rem;">
            <div style="width: 12px; height: 12px; background: #5a7b8a;"></div>
            <div class="text-muted">Terminated</div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>
