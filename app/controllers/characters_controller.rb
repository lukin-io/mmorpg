class CharactersController < ApplicationController
  def index
    @characters = Character.all
  end

  def show
  end

  def new
  end

  def edit
  end
end
