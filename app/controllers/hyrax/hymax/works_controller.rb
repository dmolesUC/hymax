# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource Hymax::Work`
module Hyrax
  # Generated controller for Hymax::Work
  class Hymax::WorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Hymax::Work

    # Use a Valkyrie aware form service to generate Valkyrie::ChangeSet style
    # forms.
    self.work_form_service = Hyrax::FormFactory.new
  end
end
