require "rails_helper"
require "hyrax/specs/shared_specs/factories/users"
require "hyrax/specs/shared_specs/factories/administrative_sets"

module Bulkrax
  RSpec.describe Importer do

    let(:basename) { File.basename(__FILE__, ".*") }

    before do
      @group_service = User.group_service
      @group_service.define_singleton_method(:add) do |*args|
        # TODO: figure out why we get "NoMethodError: undefined method `add' for class RoleMapper"
      end
    end

    after do
      # TODO: figure out why we get "NoMethodError: undefined method `add' for class RoleMapper"
      @group_service.instance_eval("undef :add", __FILE__, __LINE__)
    end

    context "Importing large file" do
      let(:file_size) { 1000 }

      let(:file_data) { SecureRandom.random_bytes(file_size) }

      let(:tmpdir) { Dir.mktmpdir(basename) }

      let(:path_to_files) do
        File.join(tmpdir, "files").tap do |path|
          FileUtils.mkdir(path)
        end
      end

      let(:file_path) do
        File.join(path_to_files, "object.bin").tap do |path|
          File.binwrite(path, file_data)
        end
      end

      let(:import_file_basename) { "import.csv" }

      let(:import_file_headers) do
        %w[file source_identifier model parent title]
      end

      let(:work_row) do
        {
          source_identifier: "w1",
          model: "Hymax::Work", # TODO: surely this is configurable
          title: "A Work"
        }
      end

      let(:fileset_row) do
        {
          file: File.basename(file_path),
          source_identifier: "fs1",
          model: "FileSet",
          title: "A FileSet",
          parent: work_row[:source_identifier]
        }
      end

      let(:import_file_path) do
        File.join(tmpdir, import_file_basename).tap do |path|
          CSV.open(path, "wb") do |csv|
            csv << import_file_headers
            [work_row, fileset_row].each do |row|
              csv << import_file_headers.map { |h| row[h.to_sym] }
            end
          end
        end
      end

      let(:user) { FactoryBot.create(:user) }

      let(:admin_set) do
        FactoryBot.valkyrie_create(
          :hyrax_admin_set,
          title: "#{basename} Admin Set",
          user: user
        )
      end

      let(:importer) do
        Bulkrax::Importer.create(
          name: basename,
          admin_set_id: admin_set.id,
          user: user,
          frequency: "PT0S",
          parser_klass: Bulkrax::CsvParser,
          parser_fields: {
            import_file_path: import_file_path
          }
        )
      end

      before do
        @queue_adapter_orig = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
        ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
      end

      after do
        ActiveJob::Base.queue_adapter = @queue_adapter_orig
      end

      after do
        FileUtils.remove_entry(tmpdir, true)
      end

      it "creates a file" do
        importer.import_objects
        expect(importer.importer_runs.count).to eq(1)
        importer_run = importer.importer_runs.take

        error_backtraces = importer_run.statuses.pluck(:error_backtrace).reject(&:empty?)
        if error_backtraces.any?
          error_backtraces.each_with_index do |ebt, i|
            $stderr.puts "Error backtrace #{i}:\n\t" + ebt.join("\n\t")
          end
        end

        work = Hyrax.query_service.find_by(id: Valkyrie::ID.new(work_row[:id]))
        expect(work).to be_a(Hyrax::Work)

        file_sets = work.file_sets
        expect(file_sets.size).to eq(1)

        file_set = file_sets[0]
        expect(file_set).to be_a(Hyrax::FileSet)
        expect(file_set.id.to_s).to eq(fileset_row[:id])

        original_file = file_set.original_file
        expect(original_file).to be_a(Hyrax::FileMetadata)
        expect(original_file.mime_type.to_s).to eq(Hyrax::FileMetadata::GENERIC_MIME_TYPE)

        file = original_file.file
        expect(file).to be_a(Valkyrie::StorageAdapter::File)
        expect(file.size).to eq(file_size)
      end
    end
  end
end