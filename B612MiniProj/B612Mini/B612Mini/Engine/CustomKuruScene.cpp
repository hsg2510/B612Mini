//
//  CustomKuruScene.cpp
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#include "CustomKuruScene.hpp"
#include "CustomRenderingEngine.hpp"

using namespace gameplay;

#pragma mark - init

namespace kuru
{
    Node* addQuadModelAndNode(Scene* scene, Mesh* mesh)
    {
        Model* model = Model::create(mesh);
        Node* node = scene->addNode();
        node->setDrawable(model);
        SAFE_RELEASE(model);
        return node;
    }
    
    Node* addQuadModelAndNode(Scene* scene, float x, float y, float width, float height,
                              float s1 = 0.0f, float t1 = 0.0f, float s2 = 1.0f, float t2 = 1.0f)
    {
        Mesh* mesh = Mesh::createQuad(x, y, width, height, s1, t1, s2, t2);
        Node* node = addQuadModelAndNode(scene, mesh);
        SAFE_RELEASE(mesh);
        return node;
    }
    
    Material* setTextureUnlitMaterial(Model* model, const char* texturePath, bool mipmap = true)
    {
        Material* material = model->setMaterial("textured.vert", "textured.frag");
        material->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
        
        // Load the texture from file.
        Texture::Sampler* sampler = material->getParameter("u_diffuseTexture")->setValue(texturePath, mipmap);
        if (mipmap)
            sampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
        else
            sampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
        sampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
        material->getStateBlock()->setCullFace(true);
        material->getStateBlock()->setDepthTest(true);
        material->getStateBlock()->setDepthWrite(true);
        return material;
    }
    
//    Node *addFullQuadModelAndNode(Scene* scene)
//    {
//        Mesh* mesh = Mesh::createQuad(-10, -10, 20, 20, 0.0, 0.0, 1.0, 1.0);
//        Node* node = addQuadModelAndNode(scene, mesh);
//        SAFE_RELEASE(mesh);
//        return node;
//    }
    
//    Material* setTextureUnlitMaterialFromData(Model* model, const char* data, bool mipmap = true)
//    {
//        Material* material = model->setMaterial("textured.vert", "textured.frag");
//        material->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
//
//        // Load the texture from file.
//        Texture::Sampler* sampler = material->getParameter("u_diffuseTexture")->setValue(data, mipmap);
//        if (mipmap)
//            sampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
//        else
//            sampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
//        sampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
//        material->getStateBlock()->setCullFace(true);
//        material->getStateBlock()->setDepthTest(true);
//        material->getStateBlock()->setDepthWrite(true);
//        return material;
//    }
    
    CustomKuruScene::CustomKuruScene() : mInternalScene(NULL)
    {
        
    }
    
    CustomKuruScene::~CustomKuruScene()
    {
        SAFE_RELEASE(mInternalScene);
    }
    
    CustomKuruScene* CustomKuruScene::create()
    {
        CustomKuruScene *sScene = new CustomKuruScene();
        sScene->addRef();
        
        return sScene;
    }
    
    void CustomKuruScene::initialize()
    {
        mInternalScene = Scene::create();
        std::cout<< Game::getInstance()->getAspectRatio() << std::endl;
        
        Camera *sCamera = Camera::createPerspective(45.0, Game::getInstance()->getAspectRatio(), 1, 1000);
        Node *sCameraNode = mInternalScene->addNode("camera");
        
        sCameraNode->setCamera(sCamera);
        mInternalScene->setActiveCamera(sCamera);
        sCameraNode->translate(0, 0, 50);
        SAFE_RELEASE(sCamera);
        
        const float cubeSize = 10.0f;
        
        Node* node = addQuadModelAndNode(mInternalScene, 0, 0, cubeSize, cubeSize);
        setTextureUnlitMaterial(dynamic_cast<Model*>(node->getDrawable()), "color-wheel.png");
    }
    
    void CustomKuruScene::update(float elapsedTime)
    {
        //nothing
    }
    
    void CustomKuruScene::render(float elapsedTime)
    {
        CustomRenderingEngine::getInstance()->clear(Game::CLEAR_COLOR_DEPTH, Vector4::zero(), 1.0, 0);
        mInternalScene->visit(this, &CustomKuruScene::drawScene);
    }
    
    bool CustomKuruScene::drawScene(Node* node)
    {
        Drawable* drawable = node->getDrawable();
        if (drawable)
            drawable->draw();
        return true;
    }
}
