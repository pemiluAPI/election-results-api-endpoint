module Pemilu
  class APIv2 < Grape::API
    version 'v2', using: :accept_version_header
    prefix 'api'
    format :json

    resource :caleg do     
      
      desc "Return all President Candidates"
      get do
        caleg = Array.new
        
        # Prepare conditions based on params
        valid_params = {          
          jenis_kelamin: 'jenis_kelamin',          
          partai: 'id_partai',          
          tahun: 'tahun'
        }
        conditions = Hash.new
        valid_params.each_pair do |key, value|
          conditions[value.to_sym] = params[key.to_sym] unless params[key.to_sym].blank?
        end

        # Set default year
        conditions[:tahun] = params[:tahun] || 2014

        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 2 : params[:limit]

        search = ["nama LIKE ? and agama LIKE ?", "%#{params[:nama]}%", "%#{params[:agama]}%"]
        
        PresidentCandidate.where(conditions)
          .where(search)          
          .limit(limit)
          .offset(params[:offset])
          .each do |capres|            
            caleg << {
              id: capres.id,
              tahun: capres.tahun,
              nama: capres.nama,
              role: capres.role,
              id_running_mate: capres.id_running_mate,
              jenis_kelamin: capres.jenis_kelamin,
              agama: capres.agama,
              tempat_lahir: capres.tempat_lahir,
              tanggal_lahir: capres.tanggal_lahir,
              status_perkawinan: capres.status_perkawinan,
              nama_pasangan: capres.nama_pasangan,
              jumlah_anak: capres.jumlah_anak,
              kelurahan_tinggal: capres.kelurahan_tinggal,
              kecamatan_tinggal: capres.kecamatan_tinggal,
              kab_kota_tinggal: capres.kab_kota_tinggal,
              provinsi_tinggal: capres.provinsi_tinggal,
              partai: {
                id: capres.id_partai,
                nama: capres.nama_partai
              },
              biografi: capres.biografi,
              riwayat_pendidikan: capres.riwayat_pendidikan_presidens,
              riwayat_pekerjaan: capres.riwayat_pekerjaan_presidens,
              riwayat_organisasi: capres.riwayat_organisasi_presidens,
              riwayat_penghargaan: capres.riwayat_penghargaan_presidens
            }
          end
          {
          results: {
            count: caleg.count,
            total: PresidentCandidate.where(conditions).where(search).count,
            caleg: caleg
          }
        }
      end
      
      desc "Return a President Candidate"
      params do
        requires :id, type: String, desc: "Candidate ID."
      end
      route_param :id do
        get do
          capres = PresidentCandidate.find_by(id: params[:id])
          {
            results: {
              count: 1,
              total: 1,
              caleg: [{
                id: capres.id,
                tahun: capres.tahun,
                nama: capres.nama,
                role: capres.role,
                id_running_mate: capres.id_running_mate,
                jenis_kelamin: capres.jenis_kelamin,
                agama: capres.agama,
                tempat_lahir: capres.tempat_lahir,
                tanggal_lahir: capres.tanggal_lahir,
                status_perkawinan: capres.status_perkawinan,
                nama_pasangan: capres.nama_pasangan,
                jumlah_anak: capres.jumlah_anak,
                kelurahan_tinggal: capres.kelurahan_tinggal,
                kecamatan_tinggal: capres.kecamatan_tinggal,
                kab_kota_tinggal: capres.kab_kota_tinggal,
                provinsi_tinggal: capres.provinsi_tinggal,
                partai: {
                  id: capres.id_partai,
                  nama: capres.nama_partai
                },
                biografi: capres.biografi,
                riwayat_pendidikan: capres.riwayat_pendidikan_presidens,
                riwayat_pekerjaan: capres.riwayat_pekerjaan_presidens,
                riwayat_organisasi: capres.riwayat_organisasi_presidens,
                riwayat_penghargaan: capres.riwayat_penghargaan_presidens
              }]
            }
          }
        end
      end
    end
    
    resource :events do     
      
      desc "Return all Events"
      get do
        events = Array.new
        capres = params[:id_calon].split(',') unless params[:id_calon].nil?
        tags = params[:tags].split(',') unless params[:tags].nil?
        
        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 500 : params[:limit]        
        by_capres_search_arr = Array.new
        if !capres.nil?
          a = 0
          capres.each do |cap|
            a += 1
            condition = "id_calon like '%#{cap}%'" if a == 1
            condition = "and id_calon like '%#{cap}%'" if a > 1
            by_capres_search_arr << condition
          end
          by_capres_search = by_capres_search_arr.join(" ")
        end
        
        if params[:after].nil? && params[:before].nil?
          by_date_search = ["tanggal_mulai >= ? or tanggal_selesai >= ?", DateTime.now.to_date, DateTime.now.to_date]
        elsif !params[:after].nil?
          if !params[:before].nil?
            by_date_search = ["(tanggal_mulai >= ? or tanggal_selesai >= ?) and (tanggal_mulai <= ? or tanggal_selesai <= ?)", params[:after], params[:after], params[:before], params[:before]]
          else by_date_search = ["tanggal_mulai >= ? or tanggal_selesai >= ?", params[:after], params[:after]]
          end
        elsif params[:after].nil?
          if !params[:before].nil?
            by_date_search = ["tanggal_mulai <= ? or tanggal_selesai <= ?", params[:before], params[:before]]
          end
        end
        
        unless params[:tags].nil?
          arr_tags = Array.new
          tags.each do |tag|
            arr_tags << tag.tr("_", " ")
          end
        end
        
        EventsPresident.includes(:events_president_tags)
          .where(by_capres_search)
          .where(by_date_search)
          .references(:events_president_tags)
          .order(:tanggal_mulai)
          .each do |event|
            tags_collection = params[:tags].nil? ? event.events_president_tags : EventsPresidentTag.where("id_schedule = ?", event.id)
            tags_data = tags_collection.map { |tag| tag.tag }
            s_tag_data = Set.new tags_data
            s_tags = Set.new arr_tags
            res = s_tags.subset? s_tag_data
            if (res == true)
              events << {
                id: event.id,
                id_calon: event.id_calon.split(','),
                judul: event.judul,
                deskripsi: event.deskripsi,
                tanggal_mulai: event.tanggal_mulai,
                waktu_mulai: event.waktu_mulai,
                tanggal_selesai: event.tanggal_selesai,
                waktu_selesai: event.waktu_selesai,
                tags: tags_data
              }
            end
          end
          results = events.take(limit.to_i).drop(params[:offset].to_i)
          {
          results: {
            count: results.count,
            total: events.count,
            events: results
          }
        }
      end
      
      desc "Return a single Event object with all its details"
      params do
        requires :id, type: String, desc: "Event ID."
      end
      route_param :id do
        get do
          event = EventsPresident.find_by(id: params[:id])
          {
            results: {
              count: 1,
              total: 1,
              event: [{
                id: event.id,
                id_calon: event.id_calon.split(','),
                judul: event.judul,
                deskripsi: event.deskripsi,
                tanggal_mulai: event.tanggal_mulai,
                waktu_mulai: event.waktu_mulai,
                tanggal_selesai: event.tanggal_selesai,
                waktu_selesai: event.waktu_selesai,
                tags: event.events_president_tags.map { |tag| tag.tag }
              }]
            }
          }
        end
      end
    end
    
    resource :videos do     
      
      desc "Return all Videos"
      get do
        videos = Array.new
        capres = params[:id_calon].split(',') unless params[:id_calon].nil?
        tags = params[:tags].split(',') unless params[:tags].nil?
        
        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 500 : params[:limit]
        
        by_capres_search_arr = Array.new
        if !capres.nil?
          a = 0
          capres.each do |cap|
            a += 1
            condition = "id_calon like '%#{cap}%'" if a == 1
            condition = "and id_calon like '%#{cap}%'" if a > 1
            by_capres_search_arr << condition
          end
          by_capres_search = by_capres_search_arr.join(" ")
        end
        
        unless params[:tags].nil?
          arr_tags = Array.new
          tags.each do |tag|
            arr_tags << tag.tr("_", " ")
          end
          by_tags_search = ["videos_president_tags.tag in (?)", arr_tags]
        end
        
        VideosPresident.includes(:videos_president_tags)
          .where(by_capres_search)
          .where(by_tags_search)
          .references(:videos_president_tags)
          .limit(limit)
          .offset(params[:offset])
          .each do |video|
            tags_collection = params[:tags].nil? ? video.videos_president_tags : VideosPresidentTag.where("id_video = ?", video.id)
            videos << {
              id: video.id,
              id_calon: video.id_calon.split(','),
              judul: video.judul,
              url_video: video.url_video,
              tanggal_direkam: video.tanggal_direkam,
              tanggal_upload: video.tanggal_upload,
              tags: tags_collection.map { |tag| tag.tag }
            }
          end
          {
          results: {
            count: videos.count,
            total: VideosPresident.includes(:videos_president_tags).where(by_capres_search).where(by_tags_search).references(:videos_president_tags).count,
            videos: videos
          }
        }
      end
      
      desc "Return a single Video object with all its details"
      params do
        requires :id, type: String, desc: "Video ID."
      end
      route_param :id do
        get do
          video = VideosPresident.find_by(id: params[:id])
          {
            results: {
              count: 1,
              total: 1,
              video: [{
              id: video.id,
              id_calon: video.id_calon.split(','),
              judul: video.judul,
              url_video: video.url_video,
              tanggal_direkam: video.tanggal_direkam,
              tanggal_upload: video.tanggal_upload,
              tags: video.videos_president_tags.map { |tag| tag.tag }
              }]
            }
          }
        end
      end
    end
    
    resource :promises do     
      
      desc "Return all Promises"
      get do
        promises = Array.new
        capres = params[:id_calon].split(',') unless params[:id_calon].nil?
        tags = params[:tags].split(',') unless params[:tags].nil?
        
        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 10 : params[:limit]
        
        by_capres_search = ["id_calon in (?)",capres] unless params[:id_calon].nil?
        
        unless params[:tags].nil?
          arr_tags = Array.new
          tags.each do |tag|
            arr_tags << tag.tr("_", " ")
          end
          by_tags_search = ["promises_president_tags.tag in (?)", arr_tags]
        end
        
        PromisesPresident.includes(:promises_president_tags)
          .where(by_capres_search)
          .where(by_tags_search)          
          .references(:promises_president_tags)
          .limit(limit)
          .offset(params[:offset])
          .each do |promise|
            tags_collection = params[:tags].nil? ? promise.promises_president_tags : PromisesPresidentTag.where("id_janji = ?", promise.id)
            promises << {
              id: promise.id,
              id_calon: promise.id_calon,
              context_janji: promise.context_janji,
              janji: promise.janji,
              tanggal: promise.tanggal,
              judul_sumber: promise.judul_sumber,
              url_sumber: promise.url_sumber,
              tags: tags_collection.map { |tag| tag.tag }
            }
          end
          {
          results: {
            count: promises.count,
            total: PromisesPresident.includes(:promises_president_tags).where(by_capres_search).where(by_tags_search).references(:promises_president_tags).count,
            promises: promises
          }
        }
      end
      
      desc "Return a single Promise object with all its details"
      params do
        requires :id, type: String, desc: "Promise ID."
      end
      route_param :id do
        get do
          promise = PromisesPresident.find_by(id: params[:id])
          {
            results: {
              count: 1,
              total: 1,
              promise: [{
              id: promise.id,
              id_calon: promise.id_calon,
              context_janji: promise.context_janji,
              janji: promise.janji,
              tanggal: promise.tanggal,
              judul_sumber: promise.judul_sumber,
              url_sumber: promise.url_sumber,
              tags: promise.promises_president_tags.map { |tag| tag.tag }
              }]
            }
          }
        end
      end
    end
  end
end