#include "register_types.h"

#include <gdextension_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "frame_buffer.h"
#include "vm.h"

using namespace godot;

void initialize_gdtemu_module(ModuleInitializationLevel p_level) {
  if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }

  ClassDB::register_class<VM>();
  ClassDB::register_class<FrameBuffer>();
}

void uninitialize_gdtemu_module(ModuleInitializationLevel p_level) {
  if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }
}

extern "C"
    // Initialization
    GDExtensionBool GDE_EXPORT
    gdtemu_library_init(const GDExtensionInterface *p_interface,
                        GDExtensionClassLibraryPtr p_library,
                        GDExtensionInitialization *r_initialization) {
  godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library,
                                                 r_initialization);

  init_obj.register_initializer(initialize_gdtemu_module);
  init_obj.register_terminator(uninitialize_gdtemu_module);
  init_obj.set_minimum_library_initialization_level(
      MODULE_INITIALIZATION_LEVEL_SCENE);

  return init_obj.init();
}
