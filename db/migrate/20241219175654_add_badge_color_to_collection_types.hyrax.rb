class AddBadgeColorToCollectionTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :hyrax_collection_types, :badge_color, :string, default: "#663333"
  end
end
