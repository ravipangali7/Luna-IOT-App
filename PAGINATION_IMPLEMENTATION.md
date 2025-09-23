# Pagination Implementation for Luna IoT App

## Overview
This implementation adds pagination support to the Vehicle and Device management screens, similar to React pagination patterns. The implementation uses a custom Django pagination format that matches the existing API response structure.

## Files Modified/Created

### 1. Models
- **`lib/models/pagination_model.dart`** - New file containing pagination data models
  - `PaginationInfo` - Contains pagination metadata (current page, total pages, etc.)
  - `PaginatedResponse<T>` - Generic wrapper for paginated API responses

### 2. API Services
- **`lib/api/api_endpoints.dart`** - Added pagination endpoints
  - `getVehiclesPaginated` - `/api/fleet/vehicle/paginated`
  - `getDevicesPaginated` - `/api/device/device/paginated`

- **`lib/api/services/vehicle_api_service.dart`** - Added pagination methods
  - `getVehiclesPaginated()` - Fetches vehicles with pagination, search, and filtering

- **`lib/api/services/device_api_service.dart`** - Added pagination methods
  - `getDevicesPaginated()` - Fetches devices with pagination, search, and filtering

### 3. Controllers
- **`lib/controllers/vehicle_controller.dart`** - Added pagination state management
  - Pagination variables: `currentPage`, `totalPages`, `totalCount`, etc.
  - Methods: `loadVehiclesPaginated()`, `nextPage()`, `previousPage()`, `goToPage()`, `changePageSize()`

- **`lib/controllers/device_controller.dart`** - Added pagination state management
  - Similar pagination variables and methods as vehicle controller

### 4. UI Components
- **`lib/widgets/pagination_widget.dart`** - New reusable pagination widget
  - `PaginationWidget` - Full-featured pagination with page numbers and page size selector
  - `CompactPaginationWidget` - Simplified version for smaller spaces

### 5. Views
- **`lib/views/vehicle/vehicle_index_screen.dart`** - Updated to use pagination
- **`lib/views/admin/device/device_index_screen.dart`** - Updated to use pagination

## Django Backend Requirements

The implementation expects the Django backend to support the following pagination endpoints:

### Vehicle Pagination Endpoint
```
GET /api/fleet/vehicle/paginated?page=1&page_size=10&search=query&filter=type
```

### Device Pagination Endpoint
```
GET /api/device/device/paginated?page=1&page_size=10&search=query&filter=type
```

### Expected Response Format
```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "data": [
    // Array of vehicle/device objects
  ],
  "pagination": {
    "count": 100,
    "next": "http://api.example.org/vehicles/paginated?page=2",
    "previous": null,
    "current_page": 1,
    "total_pages": 10,
    "page_size": 10
  }
}
```

## Django Backend Implementation

To implement the backend pagination, create a custom pagination class in Django:

```python
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

class CustomPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response({
            'success': True,
            'message': 'Data retrieved successfully',
            'data': data,
            'pagination': {
                'count': self.page.paginator.count,
                'next': self.get_next_link(),
                'previous': self.get_previous_link(),
                'current_page': self.page.number,
                'total_pages': self.page.paginator.num_pages,
                'page_size': self.page_size
            }
        })
```

Then apply this pagination class to your views:

```python
class VehicleListView(generics.ListAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    pagination_class = CustomPagination
    filter_backends = [DjangoFilterBackend, SearchFilter]
    filterset_fields = ['vehicleType', 'status']
    search_fields = ['name', 'vehicleNo', 'imei']
```

## Features

### Pagination Controls
- **Page Navigation**: Previous/Next buttons and direct page number selection
- **Page Size Selection**: Dropdown to change items per page (5, 10, 20, 50)
- **Pagination Info**: Shows "Showing X to Y of Z" information
- **Loading States**: Disabled controls during API calls

### Search and Filtering
- **Search Integration**: Search queries reset to page 1
- **Filter Integration**: Filter changes reset to page 1
- **Real-time Updates**: Pagination updates when search/filter changes

### UI Components
- **Responsive Design**: Works on different screen sizes
- **Consistent Styling**: Matches app theme and design patterns
- **Accessibility**: Proper tooltips and disabled states

## Usage

The pagination is automatically enabled for both Vehicle and Device screens. Users can:

1. **Navigate Pages**: Use Previous/Next buttons or click page numbers
2. **Change Page Size**: Select different items per page from dropdown
3. **Search**: Search queries will reset to page 1 and show paginated results
4. **Filter**: Apply filters will reset to page 1 and show paginated results

## Benefits

1. **Performance**: Only loads necessary data per page
2. **User Experience**: Faster loading and better navigation
3. **Scalability**: Handles large datasets efficiently
4. **Consistency**: Matches existing API response format
5. **Reusability**: Pagination widget can be used in other screens

## Migration Notes

- Existing `getAllVehicles()` and `getAllDevices()` methods are preserved for backward compatibility
- Controllers now use paginated loading by default (`loadVehiclesPaginated()`)
- UI automatically shows pagination controls when there are multiple pages
- No breaking changes to existing functionality
- **Graceful Fallback**: If pagination endpoints are not available on the backend, the app automatically falls back to regular endpoints and shows all data on a single page

## Error Handling

The implementation includes robust error handling:

1. **Type Casting Issues**: Fixed to handle different response formats from Django
2. **Missing Endpoints**: Gracefully falls back to regular endpoints if pagination is not implemented
3. **Network Errors**: Proper error messages and fallback behavior
4. **Empty Data**: Handles cases where data might be null or in unexpected format

## Current Status

✅ **Flutter App**: Fully implemented with fallback support
⏳ **Django Backend**: Needs pagination endpoints implementation
🔄 **Testing**: App works with existing endpoints, pagination will activate when backend is ready
