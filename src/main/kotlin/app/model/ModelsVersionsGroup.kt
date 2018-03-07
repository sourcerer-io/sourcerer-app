// Copyright 2018 Sourcerer Inc. All Rights Reserved.
// Author: Liubov Yaronskaya (lyaronskaya@sourcerer.io)

package app.model

import app.ModelsProtos.ModelVersionGroup
import app.utils.FileHelper
import com.google.protobuf.InvalidProtocolBufferException
import java.io.FileInputStream
import java.io.FileOutputStream

data class ModelsVersionsGroup(
    var languageToVersionMap: Map<String, Int> = hashMapOf()
) {
    @Throws(InvalidProtocolBufferException::class)
    constructor(proto: ModelVersionGroup) : this() {
        languageToVersionMap = proto.versionsList.map {
            it.language!! to it.version}.toMap()
    }

    @Throws(InvalidProtocolBufferException::class)
    constructor(bytes: ByteArray) : this(ModelVersionGroup.parseFrom(bytes))

    fun createEmptyProto(oStream: FileOutputStream) {
        val protoBuilder = ModelVersionGroup.newBuilder()
        protoBuilder.build().writeTo(oStream)
    }

    fun getModelsVersions(): MutableMap<String, Int> {
        return languageToVersionMap.toMutableMap()
    }

    fun updateModelVersion(language: String, version: Int, pbPath: String) {
        val protoBuilder = ModelVersionGroup.newBuilder()
        protoBuilder.mergeFrom(FileInputStream(FileHelper.getFile(pbPath)))

        if (!languageToVersionMap.containsKey(language)) {
            val modelVersionBuilder = protoBuilder.addVersionsBuilder()
            modelVersionBuilder.setLanguage(language)
            modelVersionBuilder.setVersion(version)
        } else {
            protoBuilder.getVersionsBuilder(
                protoBuilder.versionsBuilderList.indexOfFirst {
                    versionBuilder -> versionBuilder.language == language })
                    .setVersion(version)
        }

        protoBuilder.build().writeTo(FileOutputStream(FileHelper.getFile(pbPath)))
    }
}