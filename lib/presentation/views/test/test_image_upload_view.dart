import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/presentation/widgets/profile/profile_image_picker.dart';

class TestImageUploadView extends StatelessWidget {
  const TestImageUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Upload Image'),
          backgroundColor: Colors.blue,
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, profileViewModel, child) {
            if (profileViewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (profileViewModel.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${profileViewModel.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => profileViewModel.loadUserProfile(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test d\'upload d\'image',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Informations utilisateur
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations Utilisateur:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Nom: ${profileViewModel.fullName}'),
                            Text('Email: ${profileViewModel.email}'),
                            Text('Titre: ${profileViewModel.professionalTitle}'),
                            const SizedBox(height: 10),
                            Text(
                                'Image URL: ${profileViewModel.image ?? "Aucune"}'),
                            Text(
                                'Cover URL: ${profileViewModel.cover ?? "Aucune"}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Upload d'image de profil
                    const Text(
                      'Image de Profil:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(58),
                              child: profileViewModel.image != null
                                  ? Image.network(
                                      profileViewModel.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        debugPrint('Erreur image: $error');
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ProfileImagePicker(
                            currentImageUrl: profileViewModel.image,
                            isCover: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Upload d'image de couverture
                    const Text(
                      'Image de Couverture:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: profileViewModel.cover != null
                                  ? Image.network(
                                      profileViewModel.cover!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        debugPrint('Erreur cover: $error');
                                        return const Center(
                                          child: Icon(
                                            Icons.landscape,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.landscape,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ProfileImagePicker(
                            currentImageUrl: profileViewModel.cover,
                            isCover: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bouton de rafraîchissement
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => profileViewModel.refreshProfile(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser les données'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
