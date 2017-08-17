module ManageIQ::Providers
  class Openstack::NetworkManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def collect_inventory_for_targets(ems, targets)
      targets_with_data = targets.collect do |target|
        target_name = target.try(:name) || target.try(:event_type)

        _log.info("Filtering inventory for #{target.class} [#{target_name}] id: [#{target.id}]...")

        if ::Settings.ems.ems_openstack.try(:refresh).try(:inventory_object_refresh)
          inventory = ManageIQ::Providers::Openstack::Builder.build_inventory(ems, target)
        end

        _log.info("Filtering inventory...Complete")
        [target, inventory]
      end

      targets_with_data
    end

    def parse_legacy_inventory(ems)
      ManageIQ::Providers::Openstack::NetworkManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end

    def parse_targeted_inventory(ems, _target, inventory)
      log_header = format_ems_for_logging(ems)
      _log.debug("#{log_header} Parsing inventory...")
      hashes, = Benchmark.realtime_block(:parse_inventory) do
        if ::Settings.ems.ems_openstack.try(:refresh).try(:inventory_object_refresh)
          inventory.inventory_collections
        else
          ManageIQ::Providers::Openstack::NetworkManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
        end
      end
      _log.debug("#{log_header} Parsing inventory...Complete")

      hashes
    end

    def post_process_refresh_classes
      []
    end
  end
end
