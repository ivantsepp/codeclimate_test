# encoding: utf-8

module RuboCop
  module Formatter
    # This formatter displays a YAML configuration file where all cops that
    # detected any offenses are configured to not detect the offense.
    class DisabledConfigFormatter < BaseFormatter
      HEADING =
        ['# This configuration was generated by `rubocop --auto-gen-config`',
         "# on #{Time.now} using RuboCop version #{Version.version}.",
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated again.']
        .join("\n")

      @config_to_allow_offenses = {}

      COPS = Cop::Cop.all.group_by(&:cop_name)

      class << self
        attr_accessor :config_to_allow_offenses
      end

      def file_finished(_file, offenses)
        @cops_with_offenses ||= Hash.new(0)
        offenses.each { |o| @cops_with_offenses[o.cop_name] += 1 }
      end

      def finished(_inspected_files)
        output.puts HEADING

        # Syntax isn't a real cop and it can't be disabled.
        @cops_with_offenses.delete('Syntax')

        @cops_with_offenses.sort.each do |cop_name, offense_count|
          output.puts
          cfg = self.class.config_to_allow_offenses[cop_name]
          cfg ||= { 'Enabled' => false }
          output_cop_comments(output, cfg, cop_name, offense_count)
          output.puts "#{cop_name}:"
          cfg.each { |key, value| output.puts "  #{key}: #{value}" }
        end
        puts "Created #{output.path}."
        puts "Run `rubocop --config #{output.path}`, or"
        puts "add inherit_from: #{output.path} in a .rubocop.yml file."
      end

      def output_cop_comments(output, cfg, cop_name, offense_count)
        output.puts "# Offense count: #{offense_count}"
        if COPS[cop_name] && COPS[cop_name].first.new.support_autocorrect?
          output.puts '# Cop supports --auto-correct.'
        end

        default_cfg = RuboCop::ConfigLoader.default_configuration[cop_name]
        return unless default_cfg

        params = default_cfg.keys -
                 %w(Description StyleGuide Reference Enabled) -
                 cfg.keys
        return if params.empty?

        output.puts "# Configuration parameters: #{params.join(', ')}."
      end
    end
  end
end
