module Bookify
  module Render
    attr_accessor 'layout'
    attr_accessor 'style'

    def render(*args)
      args, options = Bookify.args_for(args)

      args.each do |arg|
        case arg
          when Chapter
            options[:chapter] = arg
          when Section
            options[:section] = arg
        end
      end

      template = options[:template]

      if options.has_key?(:chapter)
        chapter = options[:chapter]
        basename = template_basename_for_chapter(chapter)
        template ||= basename
        context = chapter
      end

      if options.has_key?(:section)
        section = options[:section]
        basename = template_basename_for_section(section)
        template ||= basename
        context = section
      end

      template = template.to_s
      template = File.join(layout, template) unless template[0,1]=='/'
      template += '.html.erb' unless(template.split('.').size > 1)

      template = Template.read(template)
        template.expand(context)
    end

    def template_basename_for_chapter(chapter)
      'chapter'
    end

    def template_basename_for_section(section)
      type = section.type
      result = nil

      result =
        case section.type.to_s
          when /^post/
            'section-post'
          when /^tracker/
            'section-tracker'
          when /^image/
            #['section-image', section.images.size].compact.join('-')
            ['section-image', 1].compact.join('-')
        end

      result
    ensure
      raise "no basename for #{ (section.type || section).inspect }" unless result
    end
  end
end
