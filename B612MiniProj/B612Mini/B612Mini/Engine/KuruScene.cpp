//
//  KuruScene.cpp
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 21..
//  Copyright © 2018년 Naver. All rights reserved.
//

#include "KuruScene.hpp"
#include "RenderingEngine.hpp"
#include "Camera.h"

using namespace kuru;
using namespace gameplay;


Node* addQuadModelAndNode(Scene* aScene, Mesh* aMesh)
{
    Model* sModel = Model::create(aMesh);
    Node* sNode = aScene->addNode();
    sNode->setDrawable(sModel);
    SAFE_RELEASE(sModel);
    
    return sNode;
}


Node* addQuadModelAndNode(Scene* aScene, float aX, float aY, float aWidth, float aHeight,
                          float aS1 = 0.0f, float aT1 = 0.0f, float aS2 = 1.0f, float aT2 = 1.0f)
{
    Mesh* sMesh = Mesh::createQuad(aX, aY, aWidth, aHeight, aS1, aT1, aS2, aT2);
    Node* sNode = addQuadModelAndNode(aScene, sMesh);
    SAFE_RELEASE(sMesh);
    
    return sNode;
}


Material* setTextureUnlitMaterial(Model* aModel, const char* aTexturePath, bool aMipmap = true)
{
    Material* sMaterial = aModel->setMaterial("textured.vert", "textured.frag");
    sMaterial->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
    
    // Load the texture from file.
    Texture::Sampler* sSampler = sMaterial->getParameter("u_diffuseTexture")->setValue(aTexturePath, aMipmap);
    
    if (aMipmap)
    {
        sSampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
    }
    else
    {
        sSampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
    }
    
    sSampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
    sMaterial->getStateBlock()->setCullFace(true);
    sMaterial->getStateBlock()->setDepthTest(true);
    sMaterial->getStateBlock()->setDepthWrite(true);
    
    return sMaterial;
}


#pragma mark - constructor, deconstructor


KuruScene::KuruScene(float aAspectRatio, Rectangle aViewport)
{
    mAspectRatio = aAspectRatio;
    mViewport = aViewport;
    
    init();
}

KuruScene::~KuruScene()
{
    SAFE_RELEASE(mInternalScene);
}


#pragma mark - public


void KuruScene::render(float aElapsedTime)
{
    RenderingEngine::getInstance()->clear(Game::CLEAR_COLOR_DEPTH, Vector4::zero(), 1.0f, 0);
    
    mInternalScene->visit(this, &KuruScene::drawScene);
}


#pragma mark - privates


bool KuruScene::drawScene(Node* aNode)
{
    Drawable* sDrawable = aNode->getDrawable();
    
    if (sDrawable)
    {
        sDrawable->draw();
    }
    
    return true;
}


void KuruScene::init()
{
    mInternalScene = Scene::create();
    
//    Camera *sCamera = Camera::createPerspective(45.0, mAspectRatio, 1.0, 1000.0);
    Camera *sCamera = Camera::createPerspective(Camera::DEFAULT_FIELD_OF_VIEW, 1);
    Node *sCameraNode = mInternalScene->addNode("camera");
    
    sCameraNode->setCamera(sCamera);
    mInternalScene->setActiveCamera(sCamera);
    sCameraNode->translate(0.0, 0.0, 50.0);
    
    SAFE_RELEASE(sCamera);
    
    const float cubeSize = 10.0;
    float x, y;
    
    Node *sNode = addQuadModelAndNode(mInternalScene, 0, 0, cubeSize, cubeSize);
    
    setTextureUnlitMaterial(dynamic_cast<Model*>(sNode->getDrawable()), "color-wheel.png");
    
    sNode->setTranslation(-25, cubeSize, 0);
    // Find the position of the node in screen space
    mInternalScene->getActiveCamera()->project(mViewport, sNode->getTranslationWorld(), &x, &y);
}
