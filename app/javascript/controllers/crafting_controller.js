import { Controller } from "@hotwired/stimulus"

/**
 * Stimulus controller for crafting interactions.
 * Handles recipe filtering, selection, and preview loading.
 */
export default class extends Controller {
  static targets = ["recipesGrid", "recipeSelect", "stationSelect", "preview"]

  connect() {
    console.log("Crafting controller connected")
  }

  /**
   * Filter recipes based on profession, tier, and search text
   */
  filterRecipes() {
    const professionFilter = document.getElementById("profession_filter").value
    const tierFilter = document.getElementById("tier_filter").value
    const searchFilter = document.getElementById("recipe_search").value.toLowerCase()

    const recipes = this.recipesGridTarget.querySelectorAll(".recipe-card")

    recipes.forEach(recipe => {
      const profession = recipe.dataset.professionId
      const tier = recipe.dataset.tier
      const name = recipe.dataset.name

      let visible = true

      if (professionFilter && profession !== professionFilter) {
        visible = false
      }

      if (tierFilter && tier !== tierFilter) {
        visible = false
      }

      if (searchFilter && !name.includes(searchFilter)) {
        visible = false
      }

      recipe.style.display = visible ? "" : "none"
    })
  }

  /**
   * Select a recipe from the browser
   */
  selectRecipe(event) {
    const recipeId = event.currentTarget.dataset.recipeId
    this.recipeSelectTarget.value = recipeId

    // Highlight selected recipe
    this.recipesGridTarget.querySelectorAll(".recipe-card").forEach(card => {
      card.classList.remove("recipe-card--selected")
    })
    event.currentTarget.closest(".recipe-card").classList.add("recipe-card--selected")

    // Load preview if station is also selected
    this.loadPreview()
  }

  /**
   * Load crafting preview via Turbo
   */
  async loadPreview() {
    const recipeId = this.recipeSelectTarget.value
    const stationId = this.stationSelectTarget.value

    if (!recipeId || !stationId) {
      this.previewTarget.innerHTML = '<p class="preview-placeholder">Select a recipe and station to see crafting details</p>'
      return
    }

    try {
      const response = await fetch("/crafting_jobs/preview", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          crafting_job: {
            recipe_id: recipeId,
            crafting_station_id: stationId
          }
        })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        const text = await response.text()
        this.previewTarget.innerHTML = `<p class="preview-error">${text}</p>`
      }
    } catch (error) {
      console.error("Preview load error:", error)
      this.previewTarget.innerHTML = '<p class="preview-error">Failed to load preview</p>'
    }
  }
}
