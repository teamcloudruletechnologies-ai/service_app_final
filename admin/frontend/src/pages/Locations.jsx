import { useState, useEffect } from 'react';
import { locationsAPI } from '../api';
import { toast } from 'react-toastify';
import ConfirmModal from '../components/ConfirmModal';

export default function Locations() {
  const [activeTab, setActiveTab] = useState('zones'); // 'zones' or 'pincodes'
  const [zones, setZones] = useState([]);
  const [pincodes, setPincodes] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Modals state
  const [isZoneModalOpen, setIsZoneModalOpen] = useState(false);
  const [isPincodeModalOpen, setIsPincodeModalOpen] = useState(false);
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });
  
  // Form states
  const [zoneForm, setZoneForm] = useState({ name: '', city: '', radius_km: 10, center_lat: '', center_lng: '' });
  const [pincodeForm, setPincodeForm] = useState({ code: '', zone_id: '' });

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    try {
      setLoading(true);
      if (activeTab === 'zones') {
        const res = await locationsAPI.getZones();
        setZones(res.data?.data || res.data || []);
      } else {
        const res = await locationsAPI.getPincodes();
        setPincodes(res.data?.data || res.data || []);
        // also need zones for the dropdown in pincode form
        if (zones.length === 0) {
          const zRes = await locationsAPI.getZones();
          setZones(zRes.data?.data || zRes.data || []);
        }
      }
    } catch (err) {
      console.error('Failed to fetch', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleZoneStatus = async (zone) => {
    try {
      const newStatus = zone.status === 'active' ? 'inactive' : 'active';
      await locationsAPI.updateZoneStatus(zone.id, newStatus);
      toast.success(`Zone status updated to ${newStatus}`);
      fetchData();
    } catch (err) {
      toast.error(`Error: ${err.message}`);
    }
  };

  const handleCreateZone = async (e) => {
    e.preventDefault();
    try {
      await locationsAPI.createZone(zoneForm);
      toast.success('Zone created successfully!');
      setIsZoneModalOpen(false);
      setZoneForm({ name: '', city: '', radius_km: 10, center_lat: '', center_lng: '' });
      fetchData();
    } catch (err) {
      toast.error(`Error creating zone: ${err.message}`);
    }
  };

  const handleCreatePincode = async (e) => {
    e.preventDefault();
    try {
      await locationsAPI.createPincode(pincodeForm);
      toast.success('Pincode added successfully!');
      setIsPincodeModalOpen(false);
      setPincodeForm({ code: '', zone_id: '' });
      fetchData();
    } catch (err) {
      toast.error(`Error creating pincode: ${err.message}`);
    }
  };

  const handleDeletePincode = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Delete Pincode',
      message: 'Are you sure you want to delete this pincode?',
      confirmText: 'Delete Pincode',
      variant: 'danger',
      onConfirm: async () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        try {
          await locationsAPI.deletePincode(id);
          toast.success('Pincode deleted successfully!');
          fetchData();
        } catch (err) {
          toast.error(`Error deleting pincode: ${err.message}`);
        }
      }
    });
  };

  return (
    <div className="flex-1 p-8 bg-gray-50 overflow-auto font-sans">
      <div className="max-w-6xl mx-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Location Management</h1>
            <p className="text-sm text-gray-500 mt-1">Configure service zones, geofences, and active pincodes.</p>
          </div>
          <button 
            onClick={() => activeTab === 'zones' ? setIsZoneModalOpen(true) : setIsPincodeModalOpen(true)}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors shadow-sm"
          >
            {activeTab === 'zones' ? '+ Create Zone' : '+ Add Pincode'}
          </button>
        </div>

        {/* Tabs */}
        <div className="flex space-x-1 bg-gray-200/50 p-1 rounded-lg w-max mb-6">
          <button
            onClick={() => setActiveTab('zones')}
            className={`px-5 py-2 text-sm font-medium rounded-md transition-all ${
              activeTab === 'zones' 
                ? 'bg-white text-gray-900 shadow-sm' 
                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-200/50'
            }`}
          >
            Service Zones
          </button>
          <button
            onClick={() => setActiveTab('pincodes')}
            className={`px-5 py-2 text-sm font-medium rounded-md transition-all ${
              activeTab === 'pincodes' 
                ? 'bg-white text-gray-900 shadow-sm' 
                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-200/50'
            }`}
          >
            Pincodes Configuration
          </button>
        </div>

        {/* Table Container */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            {activeTab === 'zones' ? (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                    <th className="px-6 py-4 font-semibold">Zone Name</th>
                    <th className="px-6 py-4 font-semibold">City</th>
                    <th className="px-6 py-4 font-semibold">Radius (KM)</th>
                    <th className="px-6 py-4 font-semibold">Center Coordinates</th>
                    <th className="px-6 py-4 font-semibold text-right">Status / Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {loading ? (
                    <tr><td colSpan="5" className="px-6 py-8 text-center text-gray-500">Loading zones...</td></tr>
                  ) : zones.length === 0 ? (
                    <tr><td colSpan="5" className="px-6 py-8 text-center text-gray-500">No zones configured yet.</td></tr>
                  ) : (
                    zones.map((zone) => (
                      <tr key={zone.id} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4 font-medium text-gray-900">{zone.name}</td>
                        <td className="px-6 py-4 text-sm text-gray-600">{zone.city}</td>
                        <td className="px-6 py-4 text-sm text-gray-600">{zone.radius_km} km</td>
                        <td className="px-6 py-4 text-sm text-gray-500 font-mono text-xs">
                          {zone.center_lat}, {zone.center_lng}
                        </td>
                        <td className="px-6 py-4 text-right">
                          <button 
                            onClick={() => toggleZoneStatus(zone)}
                            className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                              zone.status === 'active' 
                                ? 'bg-green-50 text-green-700 border-green-200 hover:bg-green-100' 
                                : 'bg-gray-50 text-gray-500 border-gray-200 hover:bg-gray-100'
                            }`}
                          >
                            {zone.status === 'active' ? 'Active' : 'Inactive'}
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            ) : (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                    <th className="px-6 py-4 font-semibold">Pincode</th>
                    <th className="px-6 py-4 font-semibold">Mapped Zone</th>
                    <th className="px-6 py-4 font-semibold">Coordinates (Geocoded)</th>
                    <th className="px-6 py-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {loading ? (
                    <tr><td colSpan="4" className="px-6 py-8 text-center text-gray-500">Loading pincodes...</td></tr>
                  ) : pincodes.length === 0 ? (
                    <tr><td colSpan="4" className="px-6 py-8 text-center text-gray-500">No pincodes configured yet.</td></tr>
                  ) : (
                    pincodes.map((pin) => (
                      <tr key={pin.id} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4 font-bold text-gray-900 tracking-wider">{pin.code}</td>
                        <td className="px-6 py-4 text-sm text-gray-600">
                          {pin.zone_name ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                              {pin.zone_name}
                            </span>
                          ) : (
                            <span className="text-gray-400 italic">Unassigned</span>
                          )}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500 font-mono text-xs">
                          {pin.lat ? `${pin.lat}, ${pin.lng}` : 'Pending Geocode'}
                        </td>
                        <td className="px-6 py-4 text-right">
                          <button 
                            onClick={() => handleDeletePincode(pin.id)}
                            className="text-red-600 hover:text-red-800 text-sm font-medium"
                          >
                            Remove
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Zone Modal */}
      {isZoneModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-md w-full overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
              <h3 className="text-lg font-bold text-gray-900">Create New Zone</h3>
              <button onClick={() => setIsZoneModalOpen(false)} className="text-gray-400 hover:text-gray-600">✕</button>
            </div>
            <form onSubmit={handleCreateZone} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Zone Name</label>
                <input required type="text" value={zoneForm.name} onChange={e => setZoneForm({...zoneForm, name: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none" placeholder="e.g. North Chennai" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                <input type="text" value={zoneForm.city} onChange={e => setZoneForm({...zoneForm, city: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none" placeholder="e.g. Chennai" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Coverage Radius (KM)</label>
                <input required type="number" min="1" value={zoneForm.radius_km} onChange={e => setZoneForm({...zoneForm, radius_km: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Center Latitude</label>
                  <input type="text" value={zoneForm.center_lat} onChange={e => setZoneForm({...zoneForm, center_lat: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none" placeholder="13.0827" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Center Longitude</label>
                  <input type="text" value={zoneForm.center_lng} onChange={e => setZoneForm({...zoneForm, center_lng: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none" placeholder="80.2707" />
                </div>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button type="button" onClick={() => setIsZoneModalOpen(false)} className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg shadow-sm">Create Zone</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Pincode Modal */}
      {isPincodeModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-sm w-full overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
              <h3 className="text-lg font-bold text-gray-900">Add Pincode</h3>
              <button onClick={() => setIsPincodeModalOpen(false)} className="text-gray-400 hover:text-gray-600">✕</button>
            </div>
            <form onSubmit={handleCreatePincode} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Pincode Number</label>
                <input required type="text" value={pincodeForm.code} onChange={e => setPincodeForm({...pincodeForm, code: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none font-mono text-lg tracking-wider" placeholder="600001" maxLength={10} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Assign to Zone (Optional)</label>
                <select 
                  value={pincodeForm.zone_id} 
                  onChange={e => setPincodeForm({...pincodeForm, zone_id: e.target.value})} 
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none bg-white"
                >
                  <option value="">-- None --</option>
                  {zones.map(z => (
                    <option key={z.id} value={z.id}>{z.name} ({z.city})</option>
                  ))}
                </select>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button type="button" onClick={() => setIsPincodeModalOpen(false)} className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg shadow-sm">Save Pincode</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmConfig.isOpen}
        title={confirmConfig.title}
        message={confirmConfig.message}
        confirmText={confirmConfig.confirmText}
        variant={confirmConfig.variant}
        onConfirm={confirmConfig.onConfirm}
        onClose={() => setConfirmConfig(prev => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
}
