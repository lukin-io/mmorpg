import { Controller } from "@hotwired/stimulus"

// The server owns booking, phase changes and position. This controller only
// draws the supplied trajectory and replaces its bounded terrain projection.
export default class extends Controller {
  static targets = ["pan", "terrain", "timer"]
  static values = {
    snapshotUrl: String,
    phase: String,
    deadline: String,
    serverNow: String,
    centerX: Number,
    centerY: Number,
    velocityX: Number,
    velocityY: Number,
    motionEndsAt: String
  }

  connect() {
    this.connected = true
    this.acquiredAt = performance.now()
    this.serverAt = Date.parse(this.serverNowValue)
    this.nextSnapshotAt = 0
    this.centerPan = () => {
      this.panTarget.scrollLeft = Math.max((this.panTarget.scrollWidth - this.panTarget.clientWidth) / 2, 0)
    }
    this.resizeObserver = new ResizeObserver(this.centerPan)
    this.resizeObserver.observe(this.panTarget)
    this.onVisibility = () => {
      if (document.visibilityState === "visible") this.refreshSnapshot()
    }
    document.addEventListener("visibilitychange", this.onVisibility)
    this.tick()
  }

  disconnect() {
    this.connected = false
    cancelAnimationFrame(this.frame)
    clearTimeout(this.timer)
    clearTimeout(this.requestTimeout)
    this.requestController?.abort()
    this.resizeObserver?.disconnect()
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  tick() {
    if (!this.connected || this.navigationPending) return

    const elapsed = (performance.now() - this.acquiredAt) / 1000
    const now = this.serverAt + elapsed * 1000
    const deadline = Date.parse(this.deadlineValue)
    if (this.hasTimerTarget && Number.isFinite(deadline)) {
      const remaining = Math.max(Math.ceil((deadline - now) / 1000), 0)
      this.timerTarget.textContent = this.formatTime(remaining)
      if (remaining === 0) this.refreshSnapshot()
    }

    const moving = this.phaseValue === "in_flight"
    const motionEnd = Date.parse(this.motionEndsAtValue)
    const motionElapsed = Number.isFinite(motionEnd) ? Math.max(Math.min(elapsed, (motionEnd - this.serverAt) / 1000), 0) : 0
    const centerX = this.centerXValue + (moving ? this.velocityXValue * motionElapsed : 0)
    const centerY = this.centerYValue + (moving ? this.velocityYValue * motionElapsed : 0)
    this.draw(centerX, centerY)

    if (moving) {
      if (this.nearBufferEdge(centerX, centerY) || now >= motionEnd) this.refreshSnapshot()
      this.frame = requestAnimationFrame(() => this.tick())
    } else {
      this.timer = setTimeout(() => this.tick(), 250)
    }
  }

  draw(centerX, centerY) {
    const cells = this.terrainTarget.firstElementChild
    if (!cells) return

    const originX = Number(cells.dataset.originX)
    const originY = Number(cells.dataset.originY)
    // Hold at the loaded edge during a failed or delayed read. The unbounded
    // projected center still triggers retries; a server snapshot resumes motion.
    const visibleX = Math.max(originX + 3, Math.min(centerX, originX + Number(cells.dataset.columns) - 4))
    const visibleY = Math.max(originY + 1, Math.min(centerY, originY + Number(cells.dataset.rows) - 2))
    const left = 350 - (visibleX - originX + 0.5) * 100
    const top = 150 - (visibleY - originY + 0.5) * 100
    this.terrainTarget.style.transform = `translate(${left}px, ${top}px)`
  }

  nearBufferEdge(centerX, centerY) {
    const cells = this.terrainTarget.firstElementChild
    if (!cells) return true

    const offsetX = centerX - Number(cells.dataset.originX)
    const offsetY = centerY - Number(cells.dataset.originY)
    return offsetX < 3.4 || offsetX > Number(cells.dataset.columns) - 4.4 ||
      offsetY < 1.4 || offsetY > Number(cells.dataset.rows) - 2.4
  }

  async refreshSnapshot() {
    if (!this.connected || this.navigationPending || this.requestController || performance.now() < this.nextSnapshotAt) return

    const requestController = new AbortController()
    this.requestController = requestController
    this.nextSnapshotAt = performance.now() + 500
    this.requestTimeout = setTimeout(() => requestController.abort(), 10000)
    try {
      const response = await fetch(this.snapshotUrlValue, {
        credentials: "same-origin",
        cache: "no-store",
        signal: requestController.signal,
        headers: { Accept: "application/json" }
      })
      if (!this.connected || requestController.signal.aborted) return
      if (response.status === 401 || response.status === 403) {
        // A lost session cannot recover through polling. Re-enter the HTML
        // endpoint so normal authentication/access routing owns the next page.
        this.navigationPending = true
        window.Turbo.visit(window.location.pathname, { action: "replace" })
        return
      }
      if (!response.ok) {
        this.nextSnapshotAt = performance.now() + 2000
        return
      }
      const snapshot = await response.json()
      if (!this.connected || requestController.signal.aborted) return

      if (snapshot.phase !== this.phaseValue) {
        this.navigationPending = true
        window.Turbo.visit(window.location.pathname, { action: "replace" })
        return
      }

      this.centerXValue = snapshot.center_x
      this.centerYValue = snapshot.center_y
      this.velocityXValue = snapshot.velocity_x
      this.velocityYValue = snapshot.velocity_y
      this.motionEndsAtValue = snapshot.motion_ends_at || ""
      this.serverAt = Date.parse(snapshot.server_now)
      this.acquiredAt = performance.now()
      this.deadlineValue = snapshot.deadline || ""
      this.terrainTarget.innerHTML = snapshot.map_html
      this.draw(this.centerXValue, this.centerYValue)
    } catch (error) {
      if (this.connected) this.nextSnapshotAt = performance.now() + 2000
    } finally {
      clearTimeout(this.requestTimeout)
      if (this.requestController === requestController) this.requestController = null
    }
  }

  formatTime(seconds) {
    return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60]
      .map(value => String(value).padStart(2, "0")).join(":")
  }
}
