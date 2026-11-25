import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';

/// HU_14: estado del catálogo público y del CRUD de administración.
class CategoryController extends ChangeNotifier {
  final CategoryService _categoryService;

  CategoryController([CategoryService? categoryService])
    : _categoryService = categoryService ?? CategoryService();

  List<Category> _publicCategories = const [];
  List<Category> _adminCategories = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get publicCategories => _publicCategories;
  List<Category> get adminCategories => _adminCategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadPublicCategories() async {
    _setLoading(true);
    try {
      _publicCategories = await _categoryService.listPublicCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadAdminCategories({bool incluirInactivas = true}) async {
    _setLoading(true);
    try {
      _adminCategories = await _categoryService.listCategories(
        incluirInactivas: incluirInactivas,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Category?> createCategory(CategoryInput input) async {
    _setLoading(true);
    try {
      final created = await _categoryService.createCategory(input);
      await loadAdminCategories();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory(int id, CategoryInput input) async {
    _setLoading(true);
    try {
      await _categoryService.updateCategory(id, input);
      await loadAdminCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(int id) async {
    _setLoading(true);
    try {
      await _categoryService.deleteCategory(id);
      await loadAdminCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}
