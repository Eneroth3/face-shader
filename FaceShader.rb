# NOTE: When using in an Extension, replace module name on following line with
# that of your own Extension.
module YourExtensionNamespace

  module FaceShading

    # Determine the (unshaded) color of the viewed side of a face.
    # If face is textured the average color of the texture will be used.
    # A custom plane can be supplied when previewing as if it has been moved.
    # @param [Sketchup::Face]
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)] plane
    #   Defaults to the plane of the face.
    # @param [Sketchup::Camera] camera
    #   Defaults to the camera of the same model as the face.
    # @returns [Sketchup::Color]
    def self.face_color(face, plane = nil, camera = nil)
      plane ||= face.plane
      camera ||= face.model.active_view.camera

      if back_of_plane?(plane, camera.eye)
        if face.back_material
          face.back_material.color
        else
          face.model.rendering_options["FaceBackColor"]
        end
      else
        if face.material
          face.material.color
        else
          face.model.rendering_options["FaceFrontColor"]
        end
      end
    end

    # Shade a color as it would be shaded if drawn to a face at a certain plane
    # and displayed in a certain view.
    # @param [Sketchup::Color]
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)]
    # @param [Sketchup::view]
    # @return [Sketchup::Color]
    def self.shade_color(color, plane, view)
      si = view.model.shadow_info
      light = sun_for_shading?(si) ? si["Light"]/100.0 : 0.81
      dark = sun_for_shading?(si) ? si["Dark"]/100.0 : 0.2
      shading = shade_value(plane, view)
      shift = 0.2 + dark + shading*light

      Sketchup::Color.new(*color.to_a[0, 3].map { |c| [(c*shift).to_i, 255].min })
    end

    # Compute the shaded color for the viewed side of a face.
    # A custom plane can be supplied when previewing as if it has been moved.
    # @param [Sketchup::Face]
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)] plane
    #   Defaults to the plane of the face.
    def self.shaded_face_color(face, plane = nil)
      plane ||= face.plane

      shade_color(face_color(face, plane), plane, face.model.active_view)
    end

    # Check what side of a face is being viewed.
    # Assume face is in the same coordinate system as camera.
    # @param [Sketchup::Face]
    # @param [Sketchup::Camera]
    # @return [Boolean] status
    #   +true+ if the camera is on the back side of the face,
    #   +false+ if it's on the front side.
    def self.view_back_face?(face, camera = nil)
      camera ||= face.model.active_view.camera

      back_of_plane?(face.plane, camera.eye)
    end

    private

    # Check what side of a plane a point is.
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)]
    # @param [Geom::Point3d]
    # @return [Boolean] status
    #   +true+ if the point is behind the plane (or on plane),
    #   +false+ if in front of the plane.
    def self.back_of_plane?(plane, point)
      (point - point.project_to_plane(plane)) % plane_normal(plane) < 0
    end

    # Determine the normal vector for a plane.
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)]
    # @return [Vector3d]
    def self.plane_normal(plane)
      return plane[1].clone if plane.size == 2
      a, b, c, _ = plane

      Geom::Vector3d.new(a, b, c)
    end

    # Compute how much a face at a certain plane would be shaded for a certain view.
    # @example
    #   # Select a face in the model.
    #   model = Sketchup.active_model
    #   shade_value(model.selection.first.normal, model.active_view)
    # @param [Array(Geom::Point3d, Geom::vector3d), Array(Float, Float, Float, Float)]
    # @param [Sketchup::view]
    # @return [Float] shading
    #   Shading value between 0.0 (darkest) to 1.0 (lightest).
    def self.shade_value(plane, view)
      si = view.model.shadow_info
      normal = plane_normal(plane)
      normal.reverse! if back_of_plane?(plane, view.camera.eye)
      reference =
        if sun_for_shading?(si)
          si["SunDirection"]
        else
          (view.camera.eye - view.camera.target).normalize
        end
      value = normal.normalize % reference

      sun_for_shading?(si) ? [value, 0].max : value.abs
    end

    # Check whether sun is used for shading.
    # @param [ShadowInfo]
    # @return [Boolean] status
    #   +true+ if sun is used for shading, +false+ if it isn't.
    def self.sun_for_shading?(si)
      # If shadows are enabled SketchUp uses sun for shading regardless of
      # the UseSunForAllShading setting.
      si["UseSunForAllShading"] || si["DisplayShadows"]
    end

  end

end
