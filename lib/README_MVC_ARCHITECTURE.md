# MVC Architecture with Provider State Management

This Flutter project has been restructured to follow the Model-View-Controller (MVC) architecture pattern with Provider as the primary state management solution.

## Project Structure

```
lib/
├── core/                           # Core functionality and base classes
│   ├── mvc/                       # Base MVC classes
│   │   ├── base_controller.dart   # Base controller class
│   │   ├── base_model.dart        # Base model class
│   │   └── base_view.dart         # Base view class
│   ├── providers/                 # Provider setup
│   │   ├── app_providers.dart     # Main provider configuration
│   │   └── theme_provider.dart    # Theme state management
│   └── theme/                     # Theme and styling
│       └── app_theme.dart         # App theme configuration
├── modules/                       # Feature modules
│   ├── auth/                      # Authentication module
│   │   ├── controllers/           # Auth controllers
│   │   ├── models/                # Auth models
│   │   └── views/                 # Auth views
│   └── shipper_dashboard/         # Shipper dashboard module
│       ├── controllers/           # Dashboard controllers
│       ├── models/                # Dashboard models
│       └── views/                 # Dashboard views
└── main.dart                      # App entry point
```

## Architecture Components

### 1. Models (M)
- **Purpose**: Represent data and business logic
- **Location**: `modules/{module_name}/models/`
- **Base Class**: `BaseModel`
- **Features**:
  - JSON serialization/deserialization
  - Copy with functionality
  - Equality comparison
  - Type safety

### 2. Views (V)
- **Purpose**: Handle UI and user interactions
- **Location**: `modules/{module_name}/views/`
- **Base Class**: `BaseView<T extends BaseController>`
- **Features**:
  - Automatic state management integration
  - Loading and error state handling
  - Provider integration
  - Lifecycle management

### 3. Controllers (C)
- **Purpose**: Manage business logic and state
- **Location**: `modules/{module_name}/controllers/`
- **Base Class**: `BaseController`
- **Features**:
  - State management with ChangeNotifier
  - Loading state management
  - Error handling
  - Lifecycle methods
  - Provider integration

## State Management with Provider

### Provider Setup
- **Main Configuration**: `core/providers/app_providers.dart`
- **Theme Management**: `core/providers/theme_provider.dart`
- **Integration**: All providers are configured in `main.dart`

### Key Features
- **Automatic State Updates**: Views automatically rebuild when controllers change
- **Loading States**: Built-in loading state management
- **Error Handling**: Centralized error state management
- **Theme Switching**: Light/dark theme support

## Theme System

### Theme Configuration
- **Location**: `core/theme/app_theme.dart`
- **Features**:
  - Light and dark themes
  - Consistent color palette
  - Typography system
  - Component theming
  - Material 3 support

### Color System
- **Primary Colors**: Green-based color scheme
- **Secondary Colors**: Orange accents
- **Status Colors**: Success, warning, error, info
- **Neutral Colors**: Grays and text colors

## Usage Examples

### Creating a New Module

1. **Create Model**:
```dart
class MyModel extends BaseModel {
  // Model implementation
}
```

2. **Create Controller**:
```dart
class MyController extends BaseController {
  // Controller implementation
}
```

3. **Create View**:
```dart
class MyView extends BaseView<MyController> {
  @override
  MyController createController() => MyController();
  
  @override
  Widget buildView(BuildContext context, MyController controller) {
    // View implementation
  }
}
```

### Using Providers

```dart
// In a widget
Consumer<MyController>(
  builder: (context, controller, child) {
    return Text(controller.someValue);
  },
)

// Or using context
final controller = context.read<MyController>();
```

## Benefits

1. **Separation of Concerns**: Clear separation between data, logic, and presentation
2. **Maintainability**: Easy to maintain and modify individual components
3. **Testability**: Each component can be tested independently
4. **Scalability**: Easy to add new features and modules
5. **State Management**: Centralized and predictable state management
6. **Theme Consistency**: Consistent theming across the app
7. **Code Reusability**: Base classes provide common functionality

## Best Practices

1. **Single Responsibility**: Each class should have one responsibility
2. **Dependency Injection**: Use Provider for dependency injection
3. **Error Handling**: Always handle errors gracefully
4. **Loading States**: Show loading indicators for async operations
5. **Type Safety**: Use strong typing throughout the app
6. **Documentation**: Document complex business logic
7. **Testing**: Write unit tests for controllers and models

## Migration from Existing Code

The existing screens have been refactored to follow the MVC pattern:
- `choose_role.dart` → `modules/auth/views/choose_role_view.dart`
- Shipper dashboard screens → `modules/shipper_dashboard/views/`

All existing functionality is preserved while adding the benefits of the MVC architecture.
