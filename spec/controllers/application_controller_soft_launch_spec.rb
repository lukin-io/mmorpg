# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    skip_before_action :authenticate_user!, :ensure_device_identifier, :reject_closed_game_session,
      :prepare_game_shell_context
    skip_around_action :with_airship_context, :switch_locale

    def boom
      raise "simulated gameplay crash"
    end

    def missing
      raise ActiveRecord::RecordNotFound, "missing"
    end
  end

  before do
    routes.draw do
      get "boom" => "anonymous#boom"
      get "missing" => "anonymous#missing"
    end
  end

  it "re-raises in the test environment so specs stay honest" do
    expect { get :boom }.to raise_error(RuntimeError, "simulated gameplay crash")
    expect { get :missing }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "soft-redirects unexpected errors outside local/test" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    allow(controller).to receive(:inventory_path).and_return("/inventory")
    allow(controller).to receive(:world_path).and_return("/world")

    get :boom

    expect(response).to redirect_to("/world")
    expect(flash[:alert]).to eq(I18n.t("errors.temporary_glitch"))
  end

  it "soft-redirects RecordNotFound outside local/test" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    allow(controller).to receive(:world_path).and_return("/world")

    get :missing

    expect(response).to redirect_to("/world")
    expect(flash[:alert]).to eq(I18n.t("errors.temporary_glitch"))
  end
end
